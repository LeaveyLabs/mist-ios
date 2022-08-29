//
//  MatchRequestAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

struct MatchRequestError: Codable {
    let match_requesting_user: [String]?
    let match_requested_user: [String]?
    
    let non_field_errors: [String]?
    let detail: [String]?
}

class MatchRequestAPI {
    static let PATH_TO_MATCH_REQUEST = "api/match-requests/"
    static let PATH_TO_CUSTOM_DELETE_MATCH_REQUEST_ENDPOINT = "api/delete-match-request/"
    static let SENDER_PARAM = "match_requesting_user"
    static let RECEIVER_PARAM = "match_requested_user"
    static let POST_PARAM = "post"
    
    static let MATCH_REQUEST_RECOVERY_MESSAGE = "try again later"
    
    static func filterMatchRequestErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(MatchRequestError.self, from: data)
            
            if let requestingErrors = error.match_requesting_user,
               let requestingError = requestingErrors.first {
                throw APIError.ClientError(requestingError, MATCH_REQUEST_RECOVERY_MESSAGE)
            }
            if let requestedErrors = error.match_requested_user,
               let requestedError = requestedErrors.first {
                throw APIError.ClientError(requestedError, MATCH_REQUEST_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func fetchMatchRequestsBySender(senderUserId:Int) async throws -> [MatchRequest] {
        let url = "\(Env.BASE_URL)\(PATH_TO_MATCH_REQUEST)?\(SENDER_PARAM)=\(senderUserId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterMatchRequestErrors(data: data, response: response)
        return try JSONDecoder().decode([MatchRequest].self, from: data)
    }
    
    static func fetchMatchRequestsByReceiver(receiverUserId:Int) async throws -> [MatchRequest] {
        let url = "\(Env.BASE_URL)\(PATH_TO_MATCH_REQUEST)?\(RECEIVER_PARAM)=\(receiverUserId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterMatchRequestErrors(data: data, response: response)
        return try JSONDecoder().decode([MatchRequest].self, from: data)
    }
    
    static func postMatchRequest(senderUserId:Int, receiverUserId:Int, postId:Int) async throws -> MatchRequest {
        let url = "\(Env.BASE_URL)\(PATH_TO_MATCH_REQUEST)"
        let params = [
            SENDER_PARAM: senderUserId,
            RECEIVER_PARAM: receiverUserId,
            POST_PARAM: postId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterMatchRequestErrors(data: data, response: response)
        return try JSONDecoder().decode(MatchRequest.self, from: data)
    }
    
    static func postMatchRequest(senderUserId:Int, receiverUserId:Int) async throws -> MatchRequest {
        let url = "\(Env.BASE_URL)\(PATH_TO_MATCH_REQUEST)"
        let params = [
            SENDER_PARAM: senderUserId,
            RECEIVER_PARAM: receiverUserId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterMatchRequestErrors(data: data, response: response)
        return try JSONDecoder().decode(MatchRequest.self, from: data)
    }
    
    static func deleteMatchRequest(senderUserId:Int, receiverUserId:Int) async throws {
        let endpoint = "\(Env.BASE_URL)\(PATH_TO_CUSTOM_DELETE_MATCH_REQUEST_ENDPOINT)"
        let params = "\(SENDER_PARAM)=\(senderUserId)&\(RECEIVER_PARAM)=\(receiverUserId)"
        let url = "\(endpoint)?\(params)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterMatchRequestErrors(data: data, response: response)
    }
    
    static func deleteMatchRequest(match_request_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_MATCH_REQUEST)\(match_request_id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterMatchRequestErrors(data: data, response: response)
    }
}
