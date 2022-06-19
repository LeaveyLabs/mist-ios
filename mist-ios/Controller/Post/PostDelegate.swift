//
//  PostDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/07.
//

import Foundation

protocol PostDelegate: ShareActivityDelegate {
    // Implemented below
    func likeDidTapped(post: Post)
    func favoriteDidTapped(post: Post)
    func dmDidTapped(post: Post)
    func moreDidTapped(post: Post)
    
    // Require subclass implementation
    func commentDidTapped(post: Post)
    func backgroundDidTapped(post: Post)
}

// Defining functions which are consistent across all PostDelegates

extension PostDelegate where Self: UIViewController {
    
    func likeDidTapped(post: Post) {
        //do something
    }
    
    func favoriteDidTapped(post: Post) {
        //do something
    }
    
    func dmDidTapped(post: Post) {
        
        
        let newMessageVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewMessage) as! NewMessageViewController
        let navigationController = UINavigationController(rootViewController: newMessageVC)
//        let newMessageNavVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewMessageNavigation) as! UINavigationController
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }
    
    func moreDidTapped(post: Post) {
        let moreVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.More) as! MoreViewController
        moreVC.loadViewIfNeeded() //doesnt work without this function call
        moreVC.shareDelegate = self
        present(moreVC, animated: true)
    }
    
    // ShareActivityDelegate
    func presentShareActivityVC() {
        print("hehe")
        if let url = NSURL(string: "https://www.getmist.app")  {
            let objectsToShare: [Any] = [url]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            present(activityVC, animated: true)
        }
    }
    
}
