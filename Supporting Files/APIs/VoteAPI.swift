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
    // Post vote to database
    static func postVote(vote:Vote) async throws {
        let url = "https://mist-backend.herokuapp.com/api/votes/"
        let json = try JSONEncoder().encode(vote)
        try await BasicAPI.post(url:url, jsonData:json)
    }

    // Deletes vote from database
    static func deleteVote(username:String, post_id:String) async throws {
        // Get the ID of the vote, then delete it from the database
        let id = try await getVoteID(username: username, post_id: post_id)
        let url = "https://mist-backend.herokuapp.com/api/votes/\(id)"
        try await BasicAPI.delete(url:url, jsonData:Data())
    }
    
    // Gets the ID of the vote with a given username and post_id
    static private func getVoteID(username:String, post_id:String) async throws -> [Vote] {
        // Fetch the vote from the API endpoint
        let url = "https://mist-backend.herokuapp.com/api/votes/"
        let json = try JSONEncoder().encode(["username":username, "post_id":post_id])
        let data = try await BasicAPI.fetch(url:url, jsonData:json)
        // Deserialize to get original vote
        return try JSONDecoder().decode([Vote].self, from: data)
    }

}
