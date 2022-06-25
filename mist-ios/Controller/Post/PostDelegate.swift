//
//  PostDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/07.
//

import Foundation

protocol PostDelegate: ShareActivityDelegate, AnyObject {
    // Implemented below
    func handleMoreTap()
    func handleVote(postId: Int, isAdding: Bool)
    func handleFavorite(postId: Int, isAdding: Bool)
    func handleDmTap(postId: Int, author: ReadOnlyUser)
    func beginLoadingAuthorProfilePic(postId: Int, author: ReadOnlyUser)
    func discardProfilePicTask(postId: Int)
    
    // Require subclass implementation
    func handleCommentButtonTap(postId: Int)
    func handleBackgroundTap(postId: Int)
    
    var loadAuthorProfilePicTasks: [Int: Task<FrontendReadOnlyUser?, Never>] { get set }
}

// Defining functions which are consistent across all PostDelegates

extension PostDelegate where Self: UIViewController {
    
    func beginLoadingAuthorProfilePic(postId: Int, author: ReadOnlyUser) {
        loadAuthorProfilePicTasks[postId] = Task {
            do {
                return try await FrontendReadOnlyUser(readOnlyUser: author, profilePic: UserAPI.UIImageFromURLString(url: author.picture))
            } catch {
                print("COULD NOT LOAD AUTHOR PROFILE PIC")
                return nil
            }
        }
    }

    func discardProfilePicTask(postId: Int) {
        loadAuthorProfilePicTasks.removeValue(forKey: postId)
    }

    func handleDmTap(postId: Int, author: ReadOnlyUser) {
        Task {
            if let frontendAuthor = await loadAuthorProfilePicTasks[postId]!.value {
                DispatchQueue.main.async { [self] in
                    let chatVC = ChatViewController.create(postId: postId, author: frontendAuthor)
                    let navigationController = UINavigationController(rootViewController: chatVC)
                    navigationController.modalPresentationStyle = .fullScreen
                    present(navigationController, animated: true, completion: nil)
                }
            } else {
                // :(
            }
        }
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

}
