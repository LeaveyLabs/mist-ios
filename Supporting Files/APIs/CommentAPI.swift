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
    static func fetchComments(postID:String) async throws -> [Comment] {
        let url = "https://mist-backend.herokuapp.com/api/comments?post_id=\(postID)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([Comment].self, from: data)
    }

    // Post comment to the database
    static func postComment(comment:Comment) async throws {
        let url = "https://mist-backend.herokuapp.com/api/comments/"
        let json = try JSONEncoder().encode(comment)
        try await BasicAPI.post(url:url, jsonData:json)
    }
    
    // Delete comment from database
    static func deleteComment(commentID:String) async throws {
        let url = "https://mist-backend.herokuapp.com/api/comments/\(commentID)"
        try await BasicAPI.delete(url:url, jsonData:Data())
    }
}
