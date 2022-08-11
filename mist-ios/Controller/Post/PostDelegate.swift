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
        guard loadAuthorProfilePicTasks[postId] == nil else { return } //Task was already started
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
        Task {
            if let frontendAuthor = await loadAuthorProfilePicTasks[postId]!.value {
                DispatchQueue.main.async { [self] in
                    goToChat(postId: postId, postAuthor: frontendAuthor, postTitle: title)
                }
            } else {
                DispatchQueue.main.async { [self] in
                    reloadAuthorProfilePic(postId: postId, author: author, dmButton: dmButton, title: title)
                }
            }
        }
    }
    
    func reloadAuthorProfilePic(postId: Int, author: ReadOnlyUser, dmButton: UIButton, title: String) {
        dmButton.loadingIndicator(true)
        Task {
            loadAuthorProfilePicTasks[postId] = nil
            beginLoadingAuthorProfilePic(postId: postId, author: author)
            if let reloadedAuthor = await loadAuthorProfilePicTasks[postId]!.value {
                DispatchQueue.main.async { [weak self] in
                    dmButton.loadingIndicator(false)
                    self?.goToChat(postId: postId, postAuthor: reloadedAuthor, postTitle: title)
                }
            } else {
                DispatchQueue.main.async {
                    dmButton.loadingIndicator(false)
                    CustomSwiftMessages.displayError("Something went wrong",
                                                     "Please try again later")
                }
            }
        }
    }
    
    func goToChat(postId: Int, postAuthor: FrontendReadOnlyUser, postTitle: String) {
        let chatVC = ChatViewController.createFromPost(postId: postId, postAuthor: postAuthor, postTitle: postTitle)
        let navigationController = UINavigationController(rootViewController: chatVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
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
