//
//  MyActivityVC+PostDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/11/06.
//

import Foundation
import MessageUI

//MARK: - PostDelegate

extension MyActivityViewController: PostDelegate {
    
    func handleReactTap(postId: Int) {
        reactingPostIndex = (selectedActivityFeed == .favorites ? favorites : submissions).firstIndex { $0.id == postId }
        isKeyboardForEmojiReaction = true
    }
    
    //MFMessageComposeVC
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
    
    func handleLocationTap(postId: Int) {
        guard
            let post = PostService.singleton.getPost(withPostId: postId),
            let lat = post.latitude,
            let long = post.longitude
        else { return }
        
        (tabBarController as? SpecialTabBarController)?.shouldAnimateTransition = true
        ExploreMapViewController.locationTapContext = .init(lat: lat, long: long, postId: post.id)
        tabBarController?.selectedIndex = Tabs.map.rawValue
    }
    
    func handleFavorite(postId: Int, isAdding: Bool) { // Singleton & remote update
        do {
            try FavoriteService.singleton.handleFavoriteUpdate(postId: postId, isAdding)
        } catch {
            CustomSwiftMessages.displayError(error)
        }
    }
    
    func handleVote(postId: Int, emoji: String, emojiBeforePatch: String? = nil, existingVoteRating: Int?, action: VoteAction) {
        guard
            let emojiDict = PostService.singleton.getPost(withPostId: postId)?.emoji_dict
        else { return }
        let emojiCount = emojiDict[emoji] ?? 0 //0 if the emoji has never been cast before

        var updatedEmojiDict = emojiDict
        switch action {
        case .cast:
            updatedEmojiDict[emoji] = emojiCount + VoteService.singleton.getCastingVoteRating()
        case .patch:
            guard
                let emojiBeforePatch = emojiBeforePatch,
                let existingVoteRating = existingVoteRating,
                let existingEmojiCount = emojiDict[emojiBeforePatch]
            else {
                fatalError("must provide emojiBeforePatch on patch")
            }
            updatedEmojiDict[emoji] = emojiCount + VoteService.singleton.getCastingVoteRating()
            updatedEmojiDict[emojiBeforePatch] = existingEmojiCount - existingVoteRating
        case .delete:
            guard
                let existingVoteRating = existingVoteRating  else {
                fatalError("must provide emojiBeforePatch on patch")
            }
            updatedEmojiDict[emoji] = emojiCount - existingVoteRating
        }
        PostService.singleton.updateCachedPostWith(postId: postId, updatedEmojiDict: updatedEmojiDict)
        
        // Cache & remote update
        do {
            try VoteService.singleton.handlePostVoteUpdate(postId: postId, emoji: emoji, action)
        } catch {
            PostService.singleton.updateCachedPostWith(postId: postId, updatedEmojiDict: emojiDict)
            DispatchQueue.main.async { [weak self] in
                self?.reloadAllData()
            }
            CustomSwiftMessages.displayError(error)
        }
    }
    
    func handleBackgroundTap(postId: Int) {
        view.endEditing(true)
        let tappedPost = PostService.singleton.getPost(withPostId: postId)!
        sendToPostViewFor(tappedPost, withRaisedKeyboard: false)
    }
    
    func handleCommentButtonTap(postId: Int) {
        view.endEditing(true)
        let tappedPost = PostService.singleton.getPost(withPostId: postId)!
        sendToPostViewFor(tappedPost, withRaisedKeyboard: true)
    }
    
    // Helpers
    
    func sendToPostViewFor(_ post: Post, withRaisedKeyboard: Bool) {
        let postVC = PostViewController.createPostVC(with: post, shouldStartWithRaisedKeyboard: withRaisedKeyboard, completionHandler: nil)
        navigationController!.pushViewController(postVC, animated: true)
    }
    
    func handleDeletePost(postId: Int) {
        reloadAllData()
    }
    
    //MARK: - React interaction
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        view.endEditing(true)
        guard let postView = textField.superview as? PostView else { return false }
        if !string.isSingleEmoji { return false }
        postView.handleEmojiVote(emojiString: string)
        return false
    }
    
    @objc func keyboardWillChangeFrame(sender: NSNotification) {
        let i = sender.userInfo!
        let previousK = keyboardHeight
        keyboardHeight = (i[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        
        ///don't dismiss the keyboard when toggling to emoji search, which hardly (~1px) lowers the keyboard
        /// and which does lower the keyboard at all (0px) on largest phones
        ///do dismiss it when toggling to normal keyboard, which more significantly (~49px) lowers the keyboard
        if keyboardHeight < previousK - 5 { //keyboard is going from emoji keyboard to regular keyboard
            view.endEditing(true)
        }
        
        if keyboardHeight == previousK && isKeyboardForEmojiReaction {
            //already reacting to one post, tried to react on another post
            isKeyboardForEmojiReaction = false

            //Feed:
            if let reactingPostIndex = reactingPostIndex {
                scrollFeedToPostRightAboveKeyboard(postIndex: reactingPostIndex, keyboardHeight: keyboardHeight)
            }
        }

        if keyboardHeight > previousK && isKeyboardForEmojiReaction { //keyboard is appearing for the first time && we don't want to scroll the feed when the search controller keyboard is presented
            isKeyboardForEmojiReaction = false
            if let reactingPostIndex = reactingPostIndex {
                scrollFeedToPostRightAboveKeyboard(postIndex: reactingPostIndex, keyboardHeight: keyboardHeight)
            }
        }
    }
        
    @objc func keyboardWillDismiss(sender: NSNotification) {
        keyboardHeight = 0
    }
    
    func scrollFeedToPostRightAboveKeyboard(postIndex: Int, keyboardHeight: Double) {
        let postBottomYWithinFeed = tableView.rectForRow(at: IndexPath(row: postIndex, section: 0))
        let postBottomY = tableView.convert(postBottomYWithinFeed, to: view).maxY
        
        let keyboardTopY = tableView.bounds.height - keyboardHeight
        var desiredOffset = postBottomY - keyboardTopY
        
        desiredOffset -= 50 //for some reason i need to subtract 50 to my new implementation of this with the feed

        if postIndex == 0 && desiredOffset < 0 { return }  //dont scroll up for the very first post
        tableView.setContentOffset(tableView.contentOffset.applying(.init(translationX: 0, y: desiredOffset)), animated: true)
    }
    
}
