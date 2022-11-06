//
//  ExploreMapVC+PostDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/11/05.
//

import Foundation
import MessageUI
import MapKit

extension ExploreMapViewController: PostDelegate {
    
    //MFMessageComposeVC
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
    
    func handleLocationTap(postId: Int) {
        guard
            let post = PostService.singleton.getPost(withPostId: postId),
            let _ = post.latitude,
            let _ = post.longitude
        else { return }
        
        //TODO: move to middle VC
//        if currentPage != 2 {
//            flowLayout.scrollToPage(index: 2, animated: true)
//        } else {
//            deselectAllAnnotations()
//        }
//        slowFlyTo(lat: lat, long: long, incrementalZoom: false, withDuration: cameraAnimationDuration, allTheWayIn: true) { [self] completed in
//            refreshMapPosts() { [self] in
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [self] in
//                    guard let tappedPostAnnotation = postAnnotations.first(where: { $0.post.id == postId }) else { return }
//                    let tappedPostCluster = mapView.greatestClusterContaining(tappedPostAnnotation)
//                    annotationSelectionType = .withoutPostCallout
////                    print("SELECTING:", tappedPostCluster, tappedPostAnnotation)
//                    mapView.selectAnnotation(tappedPostCluster ?? tappedPostAnnotation, animated: true)
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                        self.annotationSelectionType = .normal
//                    }
//                    //Put the tapped post first in the cluster
//                    //the below code could be replaced with a "put the post at the proper index in PostService, before rendering posts on map in refreshMapPosts()^
//                    guard let cluster = tappedPostCluster,
//                          let clusterView = mapView.view(for: cluster) as? ClusterAnnotationView
//                    else { return }
//                    guard let postIndex = clusterView.sortedMemberPosts.firstIndex(where: { $0.id == postId }) else { return }
//                    let post = clusterView.sortedMemberPosts.remove(at: postIndex)
//                    clusterView.sortedMemberPosts.insert(post, at: 0)
//                    (clusterView.annotation as? MKClusterAnnotation)?.updateClusterTitle(newTitle: clusterView.sortedMemberPosts.first?.title)
//                    clusterView.glyphText = post.topEmoji
//                }
//            }
//        }
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
//        reactingPostIndex = feedPosts.firstIndex { $0.id == postId }
        //TODO: - how to get for map^??
        
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
        }

        if keyboardHeight > previousK && isKeyboardForEmojiReaction { //keyboard is appearing for the first time && we don't want to scroll the feed when the search controller keyboard is presented
            isKeyboardForEmojiReaction = false
            if let _ = selectedAnnotationView, keyboardHeight > 100 { //keyboardHeight of 90 appears with postVC keyboard
                movePostUpAfterEmojiKeyboardRaised()
            }
        }
    }
        
    @objc func keyboardWillDismiss(sender: NSNotification) {
        keyboardHeight = 0
    }

}
