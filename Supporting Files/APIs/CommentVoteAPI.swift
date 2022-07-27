//
//  CommentVoteAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 7/26/22.
//

import Foundation

class CommentVoteAPI {
    static let PATH_TO_VOTE_MODEL = "api/comment-votes/"
    static let PATH_TO_CUSTOM_DELETE_VOTE_ENDPOINT = "api/delete-comment-vote/"
    static let VOTER_PARAM = "voter"
    static let COMMENT_PARAM = "comment"
    static let RATING_PARAM = "rating"
    
    // Get votes from a user
    static func fetchVotesByUser(voter:Int) async throws -> [CommentVote] {
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)?\(VOTER_PARAM)=\(voter)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([CommentVote].self, from: data)
    }
    
    // Gets the ID of the vote with a given username and post_id
    static func fetchVotesByVoterAndComment(voter:Int, comment:Int) async throws -> [CommentVote] {
        // Fetch the vote from the API endpoint
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)?\(VOTER_PARAM)=\(voter)&\(COMMENT_PARAM)=\(comment)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        // Deserialize to get original vote
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
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(CommentVote.self, from: data)
    }
    
    static func deleteVote(voter:Int, comment:Int) async throws  {
        let endpoint = "\(Env.BASE_URL)\(PATH_TO_CUSTOM_DELETE_VOTE_ENDPOINT)"
        let params = "\(VOTER_PARAM)=\(voter)&\(COMMENT_PARAM)=\(comment)"
        let url = "\(endpoint)?\(params)"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }

    static func deleteVote(vote_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)\(vote_id)/"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
}
