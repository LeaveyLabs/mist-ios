//
//  PostDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/07.
//

import Foundation

protocol PostDelegate: ShareActivityDelegate, AnyObject {
    // Implemented below
    func handleDmTap(postId: Int, authorId: Int)
    func handleMoreTap()
    func handleVote(postId: Int, isAdding: Bool)
    func handleFavorite(postId: Int, isAdding: Bool)
    
    // Require subclass implementation
    func handleCommentButtonTap(postId: Int)
    func handleBackgroundTap(postId: Int)
    
    //Task management
    //there should only ever be a maximum of two tasks at a time. If a third task is about to be created, it must be the same type of action as the first task, so the second and third task cancel out. Instead of adding that third task, the second task should be removed (handled below)
    var voteTasks: [Task<Void, Never>] { get set }
    var favoriteTasks: [Task<Void, Never>] { get set }
}

// Defining functions which are consistent across all PostDelegates

extension PostDelegate where Self: UIViewController {
    
    func handleDmTap(postId: Int, authorId: Int) {
        let newMessageVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewMessage) as! NewMessageViewController
        let navigationController = UINavigationController(rootViewController: newMessageVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }
    
    func handleMoreTap() {
        let moreVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.More) as! MoreViewController
        moreVC.loadViewIfNeeded() //doesnt work without this function call
        moreVC.shareDelegate = self
        present(moreVC, animated: true)
    }
    
    // ShareActivityDelegate
    func presentShareActivityVC() {
        if let url = NSURL(string: "https://www.getmist.app")  {
            let objectsToShare: [Any] = [url]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            present(activityVC, animated: true)
        }
    }
    
    //Helpers
    
    func singletonAndRemoteFavoriteUpdate(postId: Int, isAdding: Bool) {
        
        // Immediate local update
        let temporaryLocalFavorite = Favorite(id: Int.random(in: 0..<Int.max),
                                              timestamp: Date().timeIntervalSince1970,
                                              post: postId,
                                              favoriting_user: UserService.singleton.getId())
        UserService.singleton.insertTemporaryLocalFavorite(temporaryLocalFavorite)
        
        // Asynchronous remote update
        if favoriteTasks.count == 2 {
            favoriteTasks.removeLast()
        } else {
            favoriteTasks.append(Task {
    //            defer { favoriteTasks.removeFirst() }
                do {
                    if isAdding {
                        let _ = try await FavoriteAPI.postFavorite(userId: UserService.singleton.getId(), postId: postId)
                    } else {
                        let _ = try await FavoriteAPI.deleteFavorite(favorite_id: postId)
                    }
                } catch {
                    UserService.singleton.removeTemporaryLocalFavorite(temporaryLocalFavorite)
                    CustomSwiftMessages.displayError(error)
                }
                favoriteTasks.removeFirst()
            })
        }
    }
    
    //heres the thing: we want
    func singletonAndRemoteVoteUpdate(postId: Int, isAdding: Bool) {
        // Synchronous viewController update
        
        
        // Synchronous singleton update
        let temporaryLocalVote = Vote(id: Int.random(in: 0..<Int.max),
                                      voter: UserService.singleton.getId(),
                                      post: postId,
                                      timestamp: Date().timeIntervalSince1970)
        UserService.singleton.insertTemporaryLocalVote(temporaryLocalVote)
        
        // Asynchronous remote update
        if voteTasks.count == 2 {
            voteTasks.removeLast()
        } else {
            voteTasks.append(Task {
    //            defer { voteTasks.removeFirst() }
                do {
                    if isAdding {
                        let _ = try await VoteAPI.postVote(voter: UserService.singleton.getId(), post: postId)
                    } else {
                        let _ = try await VoteAPI.deleteVote(vote_id: postId)
                    }
                } catch {
                    UserService.singleton.removeTemporaryLocalVote(temporaryLocalVote) //undo singleton change
                    //undo viewController change
                    //reloadData to ensure
                    CustomSwiftMessages.displayError(error)
                }
                voteTasks.removeFirst()
            })
        }
    }

}
