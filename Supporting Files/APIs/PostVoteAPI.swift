//
//  VoteAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

struct PostVoteError: Codable {
    let voter: [String]?
    let post: [String]?
    
    let non_field_errors: [String]?
    let detail: String?
}

struct PostVoteParams: Codable {
    let voter: Int
    let post: Int
    let emoji: String
    let rating: Float?
}

class PostVoteAPI {
    static let PATH_TO_VOTE_MODEL = "api/post-votes/"
    static let PATH_TO_CUSTOM_DELETE_VOTE_ENDPOINT = "api/delete-post-vote/"
    static let PATH_TO_CUSTOM_PATCH_VOTE_ENDPOINT = "api/patch-post-vote/"
    static let VOTER_PARAM = "voter"
    static let POST_PARAM = "post"
    static let RATING_PARAM = "rating"
    static let EMOJI_PARAM = "emoji"
    
    static let POST_VOTE_RECOVERY_MESSAGE = "try again later"
    
    static func filterPostVoteErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(PostVoteError.self, from: data)
            
            if let voterErrors = error.voter,
               let voterError = voterErrors.first {
                throw APIError.ClientError(voterError, POST_VOTE_RECOVERY_MESSAGE)
            }
            if let postErrors = error.post,
               let postError = postErrors.first {
                throw APIError.ClientError(postError, POST_VOTE_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    // Get votes from a user
    static func fetchVotesByUser(voter:Int) async throws -> [PostVote] {
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)?\(VOTER_PARAM)=\(voter)"
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostVoteErrors(data: data, response: response)
        return try JSONDecoder().decode([PostVote].self, from: data)
    }
    
    // Gets the ID of the vote with a given username and post_id
    static func fetchVotesByVoterAndPost(voter:Int, post:Int) async throws -> [PostVote] {
        // Fetch the vote from the API endpoint
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)?\(VOTER_PARAM)=\(voter)&\(POST_PARAM)=\(post)"
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        // Deserialize to get original vote
        try filterPostVoteErrors(data: data, response: response)
        return try JSONDecoder().decode([PostVote].self, from: data)
    }
    
    // Post vote to database
    static func postVote(voter:Int, post:Int) async throws -> PostVote {
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)"
        let params:[String:Int] = [
            VOTER_PARAM: voter,
            POST_PARAM: post,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterPostVoteErrors(data: data, response: response)
        return try JSONDecoder().decode(PostVote.self, from: data)
    }
    
    static func postVote(voter:Int, post:Int, emoji:String) async throws -> PostVote {
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)"
        let params = PostVoteParams(voter: voter, post: post, emoji: emoji, rating:nil)
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterPostVoteErrors(data: data, response: response)
        return try JSONDecoder().decode(PostVote.self, from: data)
    }
    
    static func postVote(voter:Int, post:Int, emoji:String, rating:Float) async throws -> PostVote {
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)"
        let params = PostVoteParams(voter: voter, post: post, emoji: emoji, rating: rating)
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterPostVoteErrors(data: data, response: response)
        return try JSONDecoder().decode(PostVote.self, from: data)
    }
    
    static func patchVote(voter:Int, post:Int, emoji:String, rating:Float) async throws -> PostVote {
        let endpoint = "\(Env.BASE_URL)\(PATH_TO_CUSTOM_PATCH_VOTE_ENDPOINT)"
        let queryParams = "\(VOTER_PARAM)=\(voter)&\(POST_PARAM)=\(post)"
        let url = "\(endpoint)?\(queryParams)"
        let params = PostVoteParams(voter: voter, post: post, emoji: emoji, rating: rating)
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.PATCH.rawValue)
        try filterPostVoteErrors(data: data, response: response)
        return try JSONDecoder().decode(PostVote.self, from: data)
    }
    
    static func patchVote(voter:Int, post:Int, emoji:String) async throws -> PostVote {
        let endpoint = "\(Env.BASE_URL)\(PATH_TO_CUSTOM_PATCH_VOTE_ENDPOINT)"
        let queryParams = "\(VOTER_PARAM)=\(voter)&\(POST_PARAM)=\(post)"
        let url = "\(endpoint)?\(queryParams)"
        let params:[String:String] = [
            EMOJI_PARAM: emoji
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.PATCH.rawValue)
        try filterPostVoteErrors(data: data, response: response)
        return try JSONDecoder().decode(PostVote.self, from: data)
    }
    
    static func deleteVote(voter:Int, post:Int) async throws  {
        let endpoint = "\(Env.BASE_URL)\(PATH_TO_CUSTOM_DELETE_VOTE_ENDPOINT)"
        let params = "\(VOTER_PARAM)=\(voter)&\(POST_PARAM)=\(post)"
        let url = "\(endpoint)?\(params)"
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterPostVoteErrors(data: data, response: response)
    }

    static func deleteVote(vote_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_VOTE_MODEL)\(vote_id)/"
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterPostVoteErrors(data: data, response: response)
    }
}
