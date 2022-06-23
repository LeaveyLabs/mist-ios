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
}

// Defining functions which are consistent across all PostDelegates

extension PostDelegate where Self: UIViewController {
    
    func handleDmTap(postId: Int, authorId: Int) {
        let chatVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Chat) as! SimpleChatViewController
        let navigationController = UINavigationController(rootViewController: chatVC)
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

}
