//
//  PostDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/07.
//

import Foundation
import MessageUI

protocol PostDelegate: ShareActivityDelegate, UITextFieldDelegate, MFMessageComposeViewControllerDelegate { // , AnyObject not needed bc UITextFieldDelegate
    // Implemented below
    func handleMoreTap(postId: Int, postAuthor: Int)
    func handleFavorite(postId: Int, isAdding: Bool)
    func handleFlag(postId: Int, isAdding: Bool)
    func handleDmTap(postId: Int, authorId: Int, dmButton: UIButton, title: String)
//    func beginLoadingAuthorProfilePic(postId: Int, author: ReadOnlyUser)
    func emojiKeyboardDidDelete()
    
    //Share
    func handleShareTap(postId: Int, screenshot: UIImage)
//    func handleiMessageShare(postId: Int, screenshot: UIImage)
//    func handleInstagramShare(postId: Int, screenshot: UIImage)
//    func handleMoreShare(postId: Int, screenshot: UIImage)

    // Require subclass implementation
    func handleVote(postId: Int, emoji: String, emojiBeforePatch: String?, existingVoteRating: Int?, action: VoteAction)
    func handleCommentButtonTap(postId: Int)
    func handleBackgroundTap(postId: Int)
    func handleDeletePost(postId: Int)    
    func handleReactTap(postId: Int)
    func handleLocationTap(postId: Int)
}

// Defining functions which are consistent across all PostDelegates

extension PostDelegate where Self: UIViewController {
    
    //This isn't necessary anymore, since' we're just displaying a silhouette based on the user's userId. However, in the future, if we want to allow users to design their own avatar, this might be useful to load that in before pressing DM
//    func beginLoadingAuthorProfilePic(postId: Int, author: ReadOnlyUser) {
//        Task {
//            do {
//                let _ = try await UsersService.singleton.loadAndCacheUser(user: author)
//            } catch {
//                print("background profile loading task failed", error.localizedDescription)
//            }
//        }
//    }
    
    //MARK: - Share
    
    func handleShareTap(postId: Int, screenshot: UIImage) {
        view.endEditing(true)
        shareImage(imageToShare: screenshot, url: Constants.landingPageLink as URL)
    }

    @MainActor func handleDmTap(postId: Int, authorId: Int, dmButton: UIButton, title: String) {
        guard !BlockService.singleton.isBlockedByOrHasBlocked(authorId) else {
            CustomSwiftMessages.showAlreadyBlockedMessage()
            return
        }

        //Don't check conversations for existing match requests any more
//        guard ConversationService.singleton.getConversationWith(userId: authorId) == nil else {
//            CustomSwiftMessages.showAlreadyDmdMessage()
//            return
//        }
        
        Task {
            if let frontendAuthor = await UsersService.singleton.getPotentiallyCachedUser(userId: authorId) {
                goToChat(postId: postId, postAuthor: frontendAuthor, postTitle: title)
            } else {
                do {
                    let author = try await UserAPI.fetchUserByUserId(userId: authorId)
                    try await reloadAuthorProfilePic(postId: postId, author: author, dmButton: dmButton, title: title)
                } catch {
                    DispatchQueue.main.async {
                        dmButton.loadingIndicator(false)
                        CustomSwiftMessages.displayError(error)
                    }
                }
            }
        }
    }
    
    func reloadAuthorProfilePic(postId: Int, author: ReadOnlyUser, dmButton: UIButton, title: String) async throws {
        await dmButton.loadingIndicator(true)
        let reloadedAuthor = try await UsersService.singleton.loadAndCacheUser(user: author)
        DispatchQueue.main.async { [weak self] in
            dmButton.loadingIndicator(false)
            self?.goToChat(postId: postId, postAuthor: reloadedAuthor, postTitle: title)
        }
    }
    
    @MainActor
    func goToChat(postId: Int, postAuthor: ThumbnailReadOnlyUser, postTitle: String) {
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

extension MFMessageComposeViewControllerDelegate where Self: UIViewController {
    
    func openTextDraftWith(image: UIImage) {
        guard
//            let imageData = image.pngData(),
            let imageData = image.jpegData(compressionQuality: 1.0),
            (MFMessageComposeViewController.canSendText())
        else {
            CustomSwiftMessages.displayError("something went wrong", "")
            return
        }
        let textComposer = MFMessageComposeViewController()
        textComposer.body = ""
        
        textComposer.addAttachmentData(imageData, typeIdentifier: "image/jpg", filename: "photo.jpg")
        textComposer.recipients = []
        textComposer.messageComposeDelegate = self
        self.present(textComposer, animated: true)
    }
    
}



//    func handleiMessageShare(postId: Int, screenshot: UIImage) {
//        openTextDraftWith(image: screenshot)
//    }
//
//    func handleInstagramShare(postId: Int, screenshot: UIImage) {
//         guard let urlScheme = URL(string: "instagram-stories://share"),
//               let imageData = screenshot.pngData() else {
//             return
//         }
//
//         guard UIApplication.shared.canOpenURL(urlScheme) else {
//             print("INSTAGRAM NOT INSTALLED")
//             return
//         }
//
//         let pasterboardItems = [["com.instagram.sharedSticker.backgroundImage": imageData]]
//         let pasterboardOptions = [UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60*5)]
//
//         UIPasteboard.general.setItems(pasterboardItems, options: pasterboardOptions)
//
//         UIApplication.shared.open(urlScheme, options: [:], completionHandler: nil)
//    }
//
//    func handleMoreShare(postId: Int, screenshot: UIImage) {
//
//    }
