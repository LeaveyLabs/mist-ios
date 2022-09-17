//
//  ExploreOverlayed+Post.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/31/22.
//

import Foundation
import MapKit


protocol ExploreChildDelegate {
    func renderNewPostsOnFeed(withType reloadType: ReloadType)
    func renderNewPostsOnMap(withType reloadType: ReloadType)
    func reloadData()
    func toggleNotchHiddenAndMinimum(hidden: Bool)
    
    func reloadNewMapPostsIfNecessary()
    func reloadNewFeedPostsIfNecessary()

    var mapPosts: [Post] { get }
    var feedPosts: [Post] { get }
}

//MARK: - ExploreChildDelegate

extension ExploreParentViewController: ExploreChildDelegate {
    
    @MainActor
    func toggleNotchHiddenAndMinimum(hidden: Bool) {
        if hidden {
            overlayController.moveOverlay(toNotchAt: OverlayNotch.hidden.rawValue, animated: true, completion: nil)
        } else {
            overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: true, completion: nil)
        }
    }
    
    @MainActor
    func reloadData() {
        exploreFeedVC.feed.reloadData()
        exploreMapVC.rerenderCollectionViewForUpdatedPostData()
    }
    
    func renderNewPostsOnFeed(withType reloadType: ReloadType) {
        //Feed scroll to top, on every reload. this should happen BEFORE the datasource for the feed is altered, in order to prevent a potential improper element access
        if reloadType != .firstLoad {
            if !feedPosts.isEmpty {
                exploreFeedVC.feed.isUserInteractionEnabled = false
                exploreFeedVC.feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                exploreFeedVC.feed.isUserInteractionEnabled = true
            }
        }

        //Visual update
        exploreFeedVC.feed.reloadData()
    }
    
    func renderNewPostsOnMap(withType reloadType: ReloadType) {
        switch reloadType {
        case .firstLoad:
            exploreMapVC.turnPostsIntoAnnotationsAndReplacePostAnnotations(mapPosts)
            exploreMapVC.mapView.addAnnotations(exploreMapVC.postAnnotations)
        case .addMore: //Don't remove postAnnotations. Only add the newExploreMapPosts.
            exploreMapVC.turnPostsIntoAnnotationsAndAppendToPostAnnotations(PostService.singleton.getNewExploreMapPosts())
            exploreMapVC.mapView.addAnnotations(exploreMapVC.postAnnotations)
        case .newSearch: //Relocate map around annotations
            
            //NOTE: this is just optimized for custom explore right now because of the offset below. we should just rename this section to "customExplore"
            
            exploreMapVC.turnPostsIntoAnnotationsAndReplacePostAnnotations(mapPosts)
            //NOTE: we aren't adding place annotations within this function on newSearch as of now
            exploreMapVC.mapView.addAnnotations(exploreMapVC.postAnnotations)
            exploreMapVC.mapView.setRegion(exploreMapVC.getRegionCenteredAround(exploreMapVC.postAnnotations + exploreMapVC.placeAnnotations) ?? MKCoordinateRegion.init(center: Constants.Coordinates.USC, latitudinalMeters: 2000, longitudinalMeters: 2000), animated: true)
            let dynamicLatOffset = (exploreMapVC.latitudeOffsetForOneKMDistance / 1000) * exploreMapVC.mapView.camera.centerCoordinateDistance
            exploreMapVC.mapView.camera.centerCoordinate.latitude -= (dynamicLatOffset / 2)
            exploreMapVC.mapView.camera.pitch = exploreMapVC.maxCameraPitch //i think the pitch is droped in "setRegion"
            // we want to offset in the opposite direciton and smaller direction than usual because now the feed takes up a larger part of the bottomn

        case .newPost:
            exploreMapVC.removeExistingPostAnnotationsFromMap()
            exploreMapVC.turnPostsIntoAnnotationsAndReplacePostAnnotations(mapPosts)
            exploreMapVC.mapView.addAnnotations(exploreMapVC.postAnnotations)
        }
    }
    
}

//MARK: - Post Delegate

extension ExploreParentViewController: PostDelegate {
    
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
        renderNewPostsOnFeed(withType: .addMore)
        renderNewPostsOnMap(withType: .addMore)
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
            case .minimum, .hidden: //Map
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
