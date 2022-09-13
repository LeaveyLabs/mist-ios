//
//  ExploreOverlayed+Post.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/31/22.
//

import Foundation
import MapKit

//MARK: - ExploreChildDelegate

extension ExploreParentViewController: ExploreChildDelegate {
    
    @MainActor
    func reloadData() {
        exploreFeedVC.feed.reloadData()
        exploreMapVC.rerenderCollectionViewForUpdatedPostData()
    }
    
    func renderNewPostsOnFeedAndMap(withType reloadType: ReloadType) {
        //Feed scroll to top, on every reload. this should happen BEFORE the datasource for the feed is altered, in order to prevent a potential improper element access
        if reloadType != .firstLoad {
            if !exploreMapVC.postAnnotations.isEmpty {
                exploreFeedVC.feed.isUserInteractionEnabled = false
                exploreFeedVC.feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                exploreFeedVC.feed.isUserInteractionEnabled = true
            }
        }
        //Map camera travel, only on new searches
        exploreMapVC.removeExistingPlaceAnnotationsFromMap()
        exploreMapVC.removeExistingPostAnnotationsFromMap()
        exploreMapVC.turnPostsIntoAnnotations(mapPosts)

        //if at some point we decide to list out places in the feed results, too, then turnPlacesIntoAnnoations should be moved here
        //the reason we don't need to rn is because the feed is not dependent on place data, just post data, and we should scroll to top of feed before refreshing the data

        if reloadType == .newSearch {
            exploreMapVC.mapView.setRegion(exploreMapVC.getRegionCenteredAround(exploreMapVC.postAnnotations + exploreMapVC.placeAnnotations) ?? MKCoordinateRegion.init(center: Constants.Coordinates.USC, latitudinalMeters: 2000, longitudinalMeters: 2000), animated: true)
        }

        //Feed visual update
        exploreFeedVC.feed.reloadData()
        //Map visual update
        exploreMapVC.mapView.addAnnotations(exploreMapVC.placeAnnotations)
        exploreMapVC.mapView.addAnnotations(exploreMapVC.postAnnotations)
    }
    
}

//MARK: - Post Delegate

extension ExploreParentViewController: PostDelegate {
    
    func handleFavorite(postId: Int, isAdding: Bool) {
        // Singleton & remote update
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
                self?.reloadData() //reloadData to ensure undos are visible
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
        renderNewPostsOnFeedAndMap(withType: .refresh)
    }
    
    //MARK: - React interaction
    
    func handleReactTap(postId: Int) {
        reactingPostIndex = feedPosts.firstIndex { $0.id == postId }
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
            if currentNotch == .maximum {
                if let reactingPostIndex = reactingPostIndex {
                    exploreFeedVC.scrollFeedToPostRightAboveKeyboard(postIndex: reactingPostIndex, keyboardHeight: keyboardHeight)
                }
            }
        }
        
        if keyboardHeight > previousK && isKeyboardForEmojiReaction { //keyboard is appearing for the first time && we don't want to scroll the feed when the search controller keyboard is presented
            isKeyboardForEmojiReaction = false
            switch currentNotch {
            case .maximum: //Feed
                if let reactingPostIndex = reactingPostIndex {
                    exploreFeedVC.scrollFeedToPostRightAboveKeyboard(postIndex: reactingPostIndex, keyboardHeight: keyboardHeight)
                }
            case .minimum: //Map
                if let _ = exploreMapVC.selectedAnnotationView, keyboardHeight > 100 { //keyboardHeight of 90 appears with postVC keyboard
                    exploreMapVC.movePostUpAfterEmojiKeyboardRaised()
                }
            }
        }
    }
        
    @objc func keyboardWillDismiss(sender: NSNotification) {
        keyboardHeight = 0
        //DONT DO THE FOLLOWING IF THEY"RE CURRENTLY DRAGGING
        if let _ = exploreMapVC.selectedAnnotationView { //!postAnnotationView.isPanning { this was useful when we allowed swiping between postsAnnotationViews. not needed anymore
            exploreMapVC.movePostBackDownAfterEmojiKeyboardDismissed()
        }
    }

}
