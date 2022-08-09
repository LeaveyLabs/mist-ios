//
//  CommentDelegate.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/9/22.
//

import Foundation

protocol CommentDelegate: UITextViewDelegate {
    func handleCommentProfilePicTap(commentAuthor: FrontendReadOnlyUser)
    func handleTagTap(taggedUserId: Int?, taggedNumber: String?)
    func beginLoadingTaggedProfile(taggedUserId: Int?, taggedNumber: String?)
    var loadTaggedProfileTasks: [Int: Task<FrontendReadOnlyUser?, Error>] { get set }
    
    //UITextViewDelegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
}
