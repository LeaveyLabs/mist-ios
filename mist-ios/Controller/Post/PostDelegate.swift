//
//  PostDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/07.
//

import Foundation

protocol PostDelegate: ShareActivityDelegate, AnyObject {
    // Implemented below
    func handleMoreTap(postId: Int)
    func handleVote(postId: Int, isAdding: Bool)
    func handleFavorite(postId: Int, isAdding: Bool)
    func handleFlag(postId: Int, isAdding: Bool)
    func handleDmTap(postId: Int, author: ReadOnlyUser, dmButton: UIButton)
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
        if loadAuthorProfilePicTasks[postId] != nil { return } //Task was already started
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

    func handleDmTap(postId: Int, author: ReadOnlyUser, dmButton: UIButton) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !dmButton.isButtonCustomLoadingIndicatorVisible {
                dmButton.loadingIndicator(true)
            }
        }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                dmButton.loadingIndicator(false)
            })
        }
    }
    
    func handleFavorite(postId: Int, isAdding: Bool) {
        // Singleton & remote update
        do {
            try FavoriteService.singleton.handleFavoriteUpdate(postId: postId, isAdding)
        } catch {
            CustomSwiftMessages.displayError(error)
        }
    }
    
    func handleFlag(postId: Int, isAdding: Bool) {
        // Singleton & remote update
        do {
            try FlagService.singleton.handleFlagUpdate(postId: postId, isAdding)
        } catch {
            CustomSwiftMessages.displayError(error)
        }
    }
    
    func handleMoreTap(postId: Int) {
        let moreVC = PostMoreViewController.create(postId: postId, postDelegate: self)
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

extension UIButton {
    
    var isButtonCustomLoadingIndicatorVisible: Bool {
        get {
            return viewWithTag(808404) != nil
        }
    }
    
    func loadingIndicator(_ show: Bool) {
        let tag = 808404
        if show {
            
            self.isEnabled = false
            self.alpha = 0.5
            let indicator = UIActivityIndicatorView()
            indicator.color = .black
            let buttonHeight = self.bounds.size.height
            let buttonWidth = self.bounds.size.width
            indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
            indicator.tag = tag
            self.addSubview(indicator)
            indicator.startAnimating()
        } else {
            self.isEnabled = true
            self.alpha = 1.0
            if let indicator = self.viewWithTag(tag) as? UIActivityIndicatorView {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }
}
