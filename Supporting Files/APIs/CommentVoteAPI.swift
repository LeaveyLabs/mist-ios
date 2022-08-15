//
//  CommentVoteAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 7/26/22.
//

import Foundation

struct CommentVoteError: Codable {
    let voter: [String]?
    let comment: [String]?
    
    let non_field_errors: [String]?
    let detail: [String]?
}

class CommentVoteAPI {
    static let PATH_TO_VOTE_MODEL = "api/comment-votes/"
    static let PATH_TO_CUSTOM_DELETE_VOTE_ENDPOINT = "api/delete-comment-vote/"
    static let VOTER_PARAM = "voter"
    static let COMMENT_PARAM = "comment"
    static let RATING_PARAM = "rating"
    
    static let COMMENT_VOTE_RECOVERY_MESSAGE = "Please try again later"
    
    static func filterCommentVoteErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(CommentVoteError.self, from: data)
            
            if let voterErrors = error.voter,
               let voterError = voterErrors.first {
                throw APIError.ClientError(voterError, COMMENT_VOTE_RECOVERY_MESSAGE)
            }
            if let commentErrors = error.comment,
               let commentError = commentErrors.first {
                throw APIError.ClientError(commentError, COMMENT_VOTE_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    // Get votes from a user
    static func fetchVotesByUser(voter:Int) async throws -> [CommentVote] {
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)?\(VOTER_PARAM)=\(voter)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterCommentVoteErrors(data: data, response: response)
        return try JSONDecoder().decode([CommentVote].self, from: data)
    }
    
    // Gets the ID of the vote with a given username and post_id
    static func fetchVotesByVoterAndComment(voter:Int, comment:Int) async throws -> [CommentVote] {
        // Fetch the vote from the API endpoint
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)?\(VOTER_PARAM)=\(voter)&\(COMMENT_PARAM)=\(comment)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        // Deserialize to get original vote
        try filterCommentVoteErrors(data: data, response: response)
        return try JSONDecoder().decode([CommentVote].self, from: data)
    }
    
    // Post vote to database
    static func postVote(voter:Int, comment:Int) async throws -> CommentVote {
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)"
        let params:[String:Int] = [
            VOTER_PARAM: voter,
            COMMENT_PARAM: comment,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterCommentVoteErrors(data: data, response: response)
        return try JSONDecoder().decode(CommentVote.self, from: data)
    }
    
    static func deleteVote(voter:Int, comment:Int) async throws  {
        let endpoint = "\(Env.BASE_URL)\(PATH_TO_CUSTOM_DELETE_VOTE_ENDPOINT)"
        let params = "\(VOTER_PARAM)=\(voter)&\(COMMENT_PARAM)=\(comment)"
        let url = "\(endpoint)?\(params)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterCommentVoteErrors(data: data, response: response)
    }

    static func deleteVote(vote_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)\(vote_id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterCommentVoteErrors(data: data, response: response)
    }
}
