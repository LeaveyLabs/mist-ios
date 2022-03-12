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
    // Fetch comments from database
    static func fetchComments(id:String) async throws -> [Post] {
        // Initialize API endpoint
        guard let serviceUrl = URL(string: "https://mist-backend.herokuapp.com/api/comments/") else {
            throw CommentError.badAPIEndPoint
        }
        // Set up "id" argument
        let args: [String: String] = ["post_id":id]
        let jsonData = try JSONEncoder().encode(args)
        // Initialize API request
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "GET"
        request.httpBody = jsonData
        // Run API request
        let (data, response) = try await URLSession.shared.data(for: request)
        // Throw if unsuccessful
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw CommentError.badId
        }
        // Deserialize data and return result
        let result = try JSONDecoder().decode([Post].self, from: data)
        return result
    }

    // Creates comment in the database
    static func createPost(comment:Comment) async throws {
        // Intiailize API endpoint
        guard let serviceUrl = URL(string: "https://mist-backend.herokuapp.com/api/comments/") else {
            throw CommentError.badAPIEndPoint
        }
        // Prepare API request and JSON-formmatted comment
        var request = URLRequest(url: serviceUrl)
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(comment)
        // Specify POST + HTTP Headers
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Run the request
        try await URLSession.shared.data(for: request)
    }

}
