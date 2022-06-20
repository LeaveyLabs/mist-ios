//
//  PostDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/07.
//

import Foundation

protocol PostDelegate: ShareActivityDelegate, AnyObject {
    // Implemented below
    func handleDmTap(post: Post)
    func handleMoreTap(post: Post)
    func handleVote(post: Post, upload: Bool)
    func handleFavorite(post: Post, upload: Bool)
    
    // Require subclass implementation
    func handleCommentButtonTap(post: Post)
    func handleBackgroundTap(post: Post)
    
    //Task management
    //there should only ever be a maximum of two tasks at a time. If a third task is about to be created, it must be the same type of action as the first task, so the second and third task cancel out. Instead of adding that third task, the second task should be removed (handled below)
    var voteTasks: [Task<Void, Never>] { get set }
    var favoriteTasks: [Task<Void, Never>] { get set }
}

// Defining functions which are consistent across all PostDelegates

extension PostDelegate where Self: UIViewController {
    
    func handleDmTap(post: Post) {
        let newMessageVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewMessage) as! NewMessageViewController
        let navigationController = UINavigationController(rootViewController: newMessageVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }
    
    func handleMoreTap(post: Post) {
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
    
    func handleVote(post: Post, upload: Bool) {
        if voteTasks.count == 2 {
            voteTasks.removeLast()
        } else {
            startVoteUpdate(postId: post.id, upload: upload)
        }
    }
        
    func handleFavorite(post: Post, upload: Bool) {
        if favoriteTasks.count == 2 {
            favoriteTasks.removeLast()
        } else {
            startFavoriteUpdate(postId: post.id, upload: upload)
        }
    }
    
    //Helpers
    
    func startFavoriteUpdate(postId: Int, upload: Bool) {
        favoriteTasks.append(Task {
//            defer { favoriteTasks.removeFirst() }
            do {
                if upload {
                    try await UserService.singleton.uploadFavorite(postId: postId)
                } else {
                    try await UserService.singleton.deleteFavorite(postId: postId)
                }
            } catch {
                CustomSwiftMessages.displayError(error)
            }
        })
    }
    
    func startVoteUpdate(postId: Int, upload: Bool) {
        voteTasks.append(Task {
//            defer { voteTasks.removeFirst() }
            do {
                if upload {
                    try await UserService.singleton.uploadVote(postId: postId)
                } else {
                    try await UserService.singleton.deleteVote(postId: postId)
                }
            } catch {
                CustomSwiftMessages.displayError(error)
            }
            voteTasks.removeFirst()
        })
    }

}
