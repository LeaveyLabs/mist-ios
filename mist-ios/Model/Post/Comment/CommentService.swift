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
    var tags = [Tag]()
    var commentsPostedSinceLastFetch = [Comment]()
    
    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    func fetchTags() async throws {
        tags = try await TagAPI.fetchTags()
    }
    
    func fetchComments(postId: Int) async throws -> [Comment] {
        commentsPostedSinceLastFetch.removeAll { $0.post == postId }
        do {
            return try await CommentAPI.fetchCommentsByPostID(post: postId)
        } catch {
            print("ERROR LOADING COMMENTS", error)
            throw error
        }
    }
    
    func uploadComment(text: String, postId: Int, tags: [Tag]) async throws -> Comment {
        let newComment = try await CommentAPI.postComment(body: text, post: postId, author: UserService.singleton.getId())
        commentsPostedSinceLastFetch.append(newComment)
        if !tags.isEmpty {
            do {
                let syncedTags = try await TagAPI.batchPostTags(comment: newComment.id, tags: tags)
                return Comment(comment: newComment, tags: syncedTags)
            } catch {
                commentsPostedSinceLastFetch.removeAll { $0.id == newComment.id }
                try await CommentAPI.deleteComment(comment_id: newComment.id)
                throw error
            }
        }
        return newComment
    }
    
    func deleteComment(commentId: Int) async throws {
        try await CommentAPI.deleteComment(comment_id: commentId)
    }
    
    func getTags() -> [Tag] {
        return tags
    }
    
}
