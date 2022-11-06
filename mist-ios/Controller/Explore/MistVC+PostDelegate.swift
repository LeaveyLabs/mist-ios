//
//  MistVC+PostDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/10/13.
//

import Foundation
import MessageUI
import MapKit

extension MistCollectionViewController: PostDelegate {
    
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
//        let tappedPost = posts.first { $0.id == postId }!
        sendToPostViewFor(tappedPost, withRaisedKeyboard: false)
    }
    
    func handleCommentButtonTap(postId: Int) {
        view.endEditing(true)
        let tappedPost = PostService.singleton.getPost(withPostId: postId)!
//        let tappedPost = posts.first { $0.id == postId }!
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
    
    func handleReactTap(postId: Int) {
        if currentPage == 0 {
            reactingPostIndex = PostService.singleton.getExploreNewPostsSortedIds().firstIndex { $0 == postId }
        } else {
            reactingPostIndex = PostService.singleton.getExploreBestPostsSortedIds().firstIndex { $0 == postId }
        }
        isKeyboardForEmojiReaction = true
    }
    
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
            if currentPage <= 1 {
                if let reactingPostIndex = reactingPostIndex {
                    (collectionView.visibleCells.first as? FeedCollectionCell)?.scrollFeedToPostRightAboveKeyboard(postIndex: reactingPostIndex, keyboardHeight: keyboardHeight)
                }
            }
        }

        if keyboardHeight > previousK && isKeyboardForEmojiReaction { //keyboard is appearing for the first time && we don't want to scroll the feed when the search controller keyboard is presented
            isKeyboardForEmojiReaction = false
            if let reactingPostIndex = reactingPostIndex {
                (collectionView.visibleCells.first as? FeedCollectionCell)?.scrollFeedToPostRightAboveKeyboard(postIndex: reactingPostIndex, keyboardHeight: keyboardHeight)
            }
        }
    }
        
    @objc func keyboardWillDismiss(sender: NSNotification) {
        keyboardHeight = 0
    }

}
