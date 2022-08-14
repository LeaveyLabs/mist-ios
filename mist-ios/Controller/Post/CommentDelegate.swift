//
//  CommentDelegate.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/9/22.
//

import Foundation

protocol CommentDelegate: UITextViewDelegate {
    func handleCommentProfilePicTap(commentAuthor: FrontendReadOnlyUser)
    func handleTagTap(taggedUserId: Int?, taggedNumber: String?, taggedHandle: String)
    func beginLoadingTaggedProfile(taggedUserId: Int?, taggedNumber: String?)
    
    //UITextViewDelegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
}
