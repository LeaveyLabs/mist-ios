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
    func handleFavorite(postId: Int, isAdding: Bool)
    func handleFlag(postId: Int, isAdding: Bool)
    func handleDmTap(postId: Int, author: ReadOnlyUser, dmButton: UIButton, title: String)
    func beginLoadingAuthorProfilePic(postId: Int, author: ReadOnlyUser)
    func emojiKeyboardDidDelete()

    // Require subclass implementation
    
//    func handleVote(postId: Int, emoji: String, action: VoteAction)
    func handleVote(postId: Int, emoji: String, emojiBeforePatch: String?, existingVoteRating: Int?, action: VoteAction)
    
    func handleCommentButtonTap(postId: Int)
    func handleBackgroundTap(postId: Int)
    func handleDeletePost(postId: Int)    
//    var loadAuthorProfilePicTasks: [Int: Task<FrontendReadOnlyUser?, Never>] { get set }
    func handleReactTap(postId: Int)
}

// Defining functions which are consistent across all PostDelegates

extension PostDelegate where Self: UIViewController {
    
    func beginLoadingAuthorProfilePic(postId: Int, author: ReadOnlyUser) {
        Task {
            do {
                let _ = try await UsersService.singleton.loadAndCacheUser(user: author)
            } catch {
                print("background profile loading task failed", error.localizedDescription)
            }
        }
    }

    @MainActor func handleDmTap(postId: Int, author: ReadOnlyUser, dmButton: UIButton, title: String) {
        guard !BlockService.singleton.isBlockedByOrHasBlocked(author.id) else {
            CustomSwiftMessages.showAlreadyBlockedMessage()
            return
        }
        //Check Conversations instead of Match Requests because we might have JUST started a conversation with them but haven't sent them a text yet
        guard ConversationService.singleton.getConversationWith(userId: author.id) == nil else {
            CustomSwiftMessages.showAlreadyDmdMessage()
            return
        }
        
        Task {
            if let frontendAuthor = await UsersService.singleton.getPotentiallyCachedUser(userId: author.id) {
                goToChat(postId: postId, postAuthor: frontendAuthor, postTitle: title)
            } else {
                await reloadAuthorProfilePic(postId: postId, author: author, dmButton: dmButton, title: title)
            }
        }
    }
    
    func reloadAuthorProfilePic(postId: Int, author: ReadOnlyUser, dmButton: UIButton, title: String) async {
        await dmButton.loadingIndicator(true)
        do {
            let reloadedAuthor = try await UsersService.singleton.loadAndCacheUser(user: author)
            DispatchQueue.main.async { [weak self] in
                dmButton.loadingIndicator(false)
                self?.goToChat(postId: postId, postAuthor: reloadedAuthor, postTitle: title)
            }
        } catch {
            DispatchQueue.main.async {
                dmButton.loadingIndicator(false)
                CustomSwiftMessages.displayError("something went wrong",
                                                 "try again later")
            }
        }
    }
    
    @MainActor
    func goToChat(postId: Int, postAuthor: FrontendReadOnlyUser, postTitle: String) {
        let chatVC = ChatViewController.createFromPost(postId: postId, postAuthor: postAuthor, postTitle: postTitle)
        let navigationController = UINavigationController(rootViewController: chatVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }
    
    func handleFlag(postId: Int, isAdding: Bool) {
        // Singleton & remote update
        do {
            try FlagService.singleton.handlePostFlagUpdate(postId: postId, isAdding)
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
