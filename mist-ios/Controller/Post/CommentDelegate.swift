//
//  CommentDelegate.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/9/22.
//

import Foundation

protocol CommentDelegate: UITextViewDelegate {
    func handleCommentProfilePicTap(commentAuthor: ThumbnailReadOnlyUser)
    func handleTagTap(taggedUserId: Int?, taggedNumber: String?, taggedHandle: String)
    func beginLoadingTaggedProfile(taggedUserId: Int?, taggedNumber: String?)
    
    func handleCommentMore(commentId: Int, commentAuthor: Int)
    func handleCommentVote(commentId: Int, isAdding: Bool)
    func handleCommentFlag(commentId: Int, isAdding: Bool)
    func handleSuccessfulCommentDelete(commentId: Int)
    
    //UITextViewDelegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
}
