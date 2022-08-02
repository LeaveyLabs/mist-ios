//
//  PostDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/07.
//

import Foundation

protocol PostDelegate: ShareActivityDelegate, UITextFieldDelegate { // , AnyObject not needed bc UITextFieldDelegate
    // Implemented below
    func handleMoreTap(postId: Int, postAuthor: Int)
    func handleVote(postId: Int, emoji: String, action: VoteAction)
    func handleFavorite(postId: Int, isAdding: Bool)
    func handleFlag(postId: Int, isAdding: Bool)
    func handleDmTap(postId: Int, author: ReadOnlyUser, dmButton: UIButton, title: String)
    func beginLoadingAuthorProfilePic(postId: Int, author: ReadOnlyUser)
    func emojiKeyboardDidDelete()

    // Require subclass implementation
    func handleCommentButtonTap(postId: Int)
    func handleBackgroundTap(postId: Int)
    func handleDeletePost(postId: Int)    
    var loadAuthorProfilePicTasks: [Int: Task<FrontendReadOnlyUser?, Never>] { get set }
    func handleReactTap(postId: Int)
}

// Defining functions which are consistent across all PostDelegates

extension PostDelegate where Self: UIViewController {
    
    func beginLoadingAuthorProfilePic(postId: Int, author: ReadOnlyUser) {
        if loadAuthorProfilePicTasks[postId] != nil { return } //Task was already started
        loadAuthorProfilePicTasks[postId] = Task {
            do {
                return try await FrontendReadOnlyUser(readOnlyUser: author, profilePic: UserAPI.UIImageFromURLString(url: author.picture))
            } catch {
                print("COULD NOT LOAD AUTHOR PROFILE PIC", error.localizedDescription)
                return nil
            }
        }
    }

    func handleDmTap(postId: Int, author: ReadOnlyUser, dmButton: UIButton, title: String) {
        guard !BlockService.singleton.isBlockedByOrHasBlocked(author.id) else {
            CustomSwiftMessages.showAlreadyBlockedMessage()
            return
        }
        guard !MatchRequestService.singleton.getAllMatchRequestsWith(author.id).contains(where: {$0.post == postId} ) else {
            CustomSwiftMessages.showAlreadyDmdMessage()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dmButton.loadingIndicator(true)
        }
        Task {
            if let frontendAuthor = await loadAuthorProfilePicTasks[postId]!.value {
                DispatchQueue.main.async { [self] in
                    let chatVC = ChatViewController.createFromPost(postId: postId, postAuthor: frontendAuthor, postTitle: title)
                    let navigationController = UINavigationController(rootViewController: chatVC)
                    navigationController.modalPresentationStyle = .fullScreen
                    present(navigationController, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        dmButton.loadingIndicator(false)
                    }
                }
            } else {
                print("this should never be reached")
            }
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
    
    func handleMoreTap(postId: Int, postAuthor: Int) {
        let moreVC = PostMoreViewController.create(postId: postId, postAuthor: postAuthor, postDelegate: self)
        view.endEditing(true)
        present(moreVC, animated: true)
    }
    
    // ShareActivityDelegate
    func presentShareActivityVC() {
        presentMistShareActivity()
    }
    
    func emojiKeyboardDidDelete() {
        view.endEditing(true)
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
