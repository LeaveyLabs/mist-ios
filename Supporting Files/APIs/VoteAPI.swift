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
    
    // Post vote to database
    static func postVote(voter:Int, post:Int, rating:Int) async throws -> Vote {
        let url = "\(BASE_URL)\(PATH_TO_VOTE_MODEL)"
        let params:[String:Int] = [
            VOTER_PARAM: voter,
            POST_PARAM: post,
            RATING_PARAM: rating,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(Vote.self, from: data)
    }

    // Deletes vote from database
    static func deleteVote(voter:Int, post:Int) async throws {
        // Get the ID of the vote, then delete it from the database
        let votes = try await getVoteByVoterAndPost(voter: voter, post: post)
        let id = votes[0].id
        let url = "\(BASE_URL)\(PATH_TO_VOTE_MODEL)\(id)/"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
    
    // Gets the ID of the vote with a given username and post_id
    static private func getVoteByVoterAndPost(voter:Int, post:Int) async throws -> [Vote] {
        // Fetch the vote from the API endpoint
        let url = "\(BASE_URL)\(PATH_TO_VOTE_MODEL)?\(VOTER_PARAM)=\(voter)&\(POST_PARAM)=\(post)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        // Deserialize to get original vote
        return try JSONDecoder().decode([Vote].self, from: data)
    }

}
