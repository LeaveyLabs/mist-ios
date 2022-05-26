//
//  CommentAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

enum CommentError: Error {
    case badAPIEndPoint
    case badId
}

class CommentAPI {
    // Fetch comments from database with the given postID
    static func fetchCommentsByPostID(post:Int) async throws -> [Comment] {
        let url = "https://mist-backend.herokuapp.com/api/comments?post_id=\(post)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: "GET")
        return try JSONDecoder().decode([Comment].self, from: data)
    }

    // Post comment to the database
    static func postComment(text: String,
                            post: Int,
                            author: Int) async throws -> Comment {
        let newComment = Comment(text: text,
                                 post: post,
                                 author: author)
        let url = "https://mist-backend.herokuapp.com/api/comments/"
        let json = try JSONEncoder().encode(newComment)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: "POST")
        return try JSONDecoder().decode(Comment.self, from: data)
    }
    
    // Delete comment from database
    static func deleteComment(comment:Int) async throws {
        let url = "https://mist-backend.herokuapp.com/api/comments/\(comment)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: "DELETE")
        let _ = try JSONDecoder().decode(Comment.self, from: data)
    }
}
