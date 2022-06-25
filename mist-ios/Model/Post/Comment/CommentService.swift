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
    
    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    func uploadComment(text: String, postId: Int) async throws -> Comment {
        return try await CommentAPI.postComment(body: text, post: postId, author: UserService.singleton.getId())
    }
    
    func deleteComment(commentId: Int, postId: Int) async throws {
        try await CommentAPI.deleteComment(comment_id: commentId)
    }
    
}
