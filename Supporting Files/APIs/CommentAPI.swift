//
//  CommentAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

struct CommentError: Codable {
    let post: [String]?
    let body: [String]?
    let author: [String]?
    // Error
    let non_field_errors: [String]?
    let detail: String?
}

class CommentAPI {
    static let PATH_TO_COMMENT_MODEL = "api/comments/"
    static let BODY_PARAM = "body"
    static let POST_PARAM = "post"
    static let AUTHOR_PARAM = "author"
    
    static let COMMENT_RECOVERY_MESSAGE = "Please try again later"
    
    static func filterCommentErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(CommentError.self, from: data)
            
            if let postErrors = error.post,
               let postError = postErrors.first {
                throw APIError.ClientError(postError, COMMENT_RECOVERY_MESSAGE)
            }
            if let bodyErrors = error.body,
               let bodyError = bodyErrors.first {
                throw APIError.ClientError(bodyError, COMMENT_RECOVERY_MESSAGE)
            }
            if let authorErrors = error.author,
               let authorError = authorErrors.first {
                throw APIError.ClientError(authorError, COMMENT_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    // Fetch comments from database with the given postID
    static func fetchCommentsByPostID(post:Int) async throws -> [Comment] {
        let url = "\(Env.BASE_URL)\(PATH_TO_COMMENT_MODEL)?\(POST_PARAM)=\(post)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterCommentErrors(data: data, response: response)
        return try JSONDecoder().decode([Comment].self, from: data)
    }

    // Post comment to the database
    static func postComment(body: String,
                            post: Int,
                            author: Int) async throws -> Comment {
        let url = "\(Env.BASE_URL)\(PATH_TO_COMMENT_MODEL)"
        let params:[String:String] = [
            BODY_PARAM: body,
            POST_PARAM: String(post),
            AUTHOR_PARAM: String(author),
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterCommentErrors(data: data, response: response)
        return try JSONDecoder().decode(Comment.self, from: data)
    }
    
    // Delete comment from database
    static func deleteComment(comment_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_COMMENT_MODEL)\(comment_id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterCommentErrors(data: data, response: response)
    }
}
