//
//  CommentService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

//Note: this class doesn't actually really do anything right nowexcept call the CommentAPI

class CommentService: NSObject {
    
    static var singleton = CommentService()
    
    //TBH: We should also cache comments here. dont need to reload comments when you were just there.
    //dictionary of [postId: [Comment]]
        //buttt what if you wanna reload comments? there's no refresh button...
        //let's pass on this for now
    
    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    func uploadComment(text: String, postId: Int, tags: [Tag]) async throws -> Comment {
        let newComment = try await CommentAPI.postComment(body: text, post: postId, author: UserService.singleton.getId())
        if !tags.isEmpty {
            tags.forEach { tag in
                print(tag.tagged_phone_number)
            }
            do {
                let syncedTags = try await TagAPI.batchPostTags(comment: newComment.id, tags: tags)
                return Comment(comment: newComment, tags: syncedTags)
            } catch {
                try await CommentAPI.deleteComment(comment_id: newComment.id)
                throw error
            }
        }
        return newComment
    }
    
    func deleteComment(commentId: Int, postId: Int) async throws {
        try await CommentAPI.deleteComment(comment_id: commentId)
    }
    
}
