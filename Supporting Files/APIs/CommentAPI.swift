//
//  CommentAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

class CommentAPI {
    static let PATH_TO_COMMENT_MODEL = "api/comments/"
    static let POST_ID_PARAM = "post_id"
    // Fetch comments from database with the given postID
    static func fetchCommentsByPostID(post:Int) async throws -> [Comment] {
        let url = "\(BASE_URL)\(PATH_TO_COMMENT_MODEL)?\(POST_ID_PARAM)=\(post)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Comment].self, from: data)
    }

    // Post comment to the database
    static func postComment(text: String,
                            post: Int,
                            author: Int) async throws -> Comment {
        let newComment = Comment(body: text,
                                 post: post,
                                 author: author)
        let url = "\(BASE_URL)\(PATH_TO_COMMENT_MODEL)"
        let json = try JSONEncoder().encode(newComment)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(Comment.self, from: data)
    }
    
    // Delete comment from database
    static func deleteComment(commentId:Int) async throws {
        let url = "\(BASE_URL)\(PATH_TO_COMMENT_MODEL)\(commentId)/"
        let _ = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
}
