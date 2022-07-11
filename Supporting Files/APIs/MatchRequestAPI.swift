//
//  MatchRequestAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

class MatchRequestAPI {
    static let PATH_TO_MATCH_REQUEST = "api/match-requests/"
    static let PATH_TO_CUSTOM_DELETE_MATCH_REQUEST_ENDPOINT = "api/delete-match-request/"
    static let SENDER_PARAM = "match_requesting_user"
    static let RECEIVER_PARAM = "match_requested_user"
    static let POST_PARAM = "post"
    
    static func fetchMatchRequestsBySender(senderUserId:Int) async throws -> [MatchRequest] {
        let url = "\(BASE_URL)\(PATH_TO_MATCH_REQUEST)?\(SENDER_PARAM)=\(senderUserId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([MatchRequest].self, from: data)
    }
    
    static func fetchMatchRequestsByReceiver(receiverUserId:Int) async throws -> [MatchRequest] {
        let url = "\(BASE_URL)\(PATH_TO_MATCH_REQUEST)?\(RECEIVER_PARAM)=\(receiverUserId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([MatchRequest].self, from: data)
    }
    
    static func postMatchRequest(senderUserId:Int, receiverUserId:Int, postId:Int) async throws -> MatchRequest {
        let url = "\(BASE_URL)\(PATH_TO_MATCH_REQUEST)"
        let params = [
            SENDER_PARAM: senderUserId,
            RECEIVER_PARAM: receiverUserId,
            POST_PARAM: postId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(MatchRequest.self, from: data)
    }
    
    static func postMatchRequest(senderUserId:Int, receiverUserId:Int) async throws -> MatchRequest {
        let url = "\(BASE_URL)\(PATH_TO_MATCH_REQUEST)"
        let params = [
            SENDER_PARAM: senderUserId,
            RECEIVER_PARAM: receiverUserId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(MatchRequest.self, from: data)
    }
    
    static func deleteMatchRequest(senderUserId:Int, receiverUserId:Int) async throws {
        let endpoint = "\(BASE_URL)\(PATH_TO_CUSTOM_DELETE_MATCH_REQUEST_ENDPOINT)"
        let params = "\(SENDER_PARAM)=\(senderUserId)&\(RECEIVER_PARAM)=\(receiverUserId)"
        let url = "\(endpoint)?\(params)"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
    
    static func deleteMatchRequest(match_request_id:Int) async throws {
        let url = "\(BASE_URL)\(PATH_TO_MATCH_REQUEST)\(match_request_id)/"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
}
