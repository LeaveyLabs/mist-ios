//
//  VoteAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

enum VoteError: Error {
    case badAPIEndPoint
    case badParams
}

class VoteAPI {
    static let PATH_TO_VOTE_MODEL = "api/votes/"
    static let VOTER_PARAM = "voter"
    static let POST_PARAM = "post"
    static let RATING_PARAM = "rating"
    
    // Get votes from a user
    static func fetchVotesByUser(voter:Int) async throws -> [Vote] {
        let url = "\(BASE_URL)\(PATH_TO_VOTE_MODEL)?\(VOTER_PARAM)=\(voter)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Vote].self, from: data)
    }
    
    // Gets the ID of the vote with a given username and post_id
    static func fetchVotesByVoterAndPost(voter:Int, post:Int) async throws -> [Vote] {
        // Fetch the vote from the API endpoint
        let url = "\(BASE_URL)\(PATH_TO_VOTE_MODEL)?\(VOTER_PARAM)=\(voter)&\(POST_PARAM)=\(post)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        // Deserialize to get original vote
        return try JSONDecoder().decode([Vote].self, from: data)
    }
    
    // Post vote to database
    static func postVote(voter:Int, post:Int) async throws -> Vote {
        let url = "\(BASE_URL)\(PATH_TO_VOTE_MODEL)"
        let params:[String:Int] = [
            VOTER_PARAM: voter,
            POST_PARAM: post,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(Vote.self, from: data)
    }
    
    static func deleteVote(voter:Int, post:Int) async throws  {
        let userVotes = try await VoteAPI.fetchVotesByVoterAndPost(voter: voter, post: post)
        guard userVotes.count == 1 else {
            throw APIError.NotFound
        }
        let _ = try await VoteAPI.deleteVote(vote_id: userVotes[0].id)
    }

    static func deleteVote(vote_id:Int) async throws {
        let url = "\(BASE_URL)\(PATH_TO_VOTE_MODEL)\(vote_id)/"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
}
