//
//  FriendRequestAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

struct FriendRequestError: Codable {
    let friend_requesting_user: [String]?
    let friend_requested_user: [String]?
    
    let non_field_errors: [String]?
    let detail: [String]?
}

class FriendRequestAPI {
    static let PATH_TO_FRIEND_REQUESTS = "api/friend-requests/"
    static let PATH_TO_CUSTOM_DELETE_FRIEND_REQUEST_ENDPOINT = "api/delete-friend-request/"
    static let SENDER_PARAM = "friend_requesting_user"
    static let RECEIVER_PARAM = "friend_requested_user"
    
    static let FRIEND_REQUEST_RECOVERY_MESSAGE = "try again later"
    
    static func filterFriendRequestErrors(data: Data, response: HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(FriendRequestError.self, from: data)
            
            if let requestingErrors = error.friend_requesting_user,
               let requestingError = requestingErrors.first {
                throw APIError.ClientError(requestingError, FRIEND_REQUEST_RECOVERY_MESSAGE)
            }
            if let requestedErrors = error.friend_requested_user,
               let requestedError = requestedErrors.first {
                throw APIError.ClientError(requestedError, FRIEND_REQUEST_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func fetchFriendRequestsBySender(senderUserId:Int) async throws -> [FriendRequest] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FRIEND_REQUESTS)?\(SENDER_PARAM)=\(senderUserId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterFriendRequestErrors(data: data, response: response)
        return try JSONDecoder().decode([FriendRequest].self, from: data)
    }
    
    static func fetchFriendRequestsByReceiver(receiverUserId:Int) async throws -> [FriendRequest] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FRIEND_REQUESTS)?\(RECEIVER_PARAM)=\(receiverUserId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterFriendRequestErrors(data: data, response: response)
        return try JSONDecoder().decode([FriendRequest].self, from: data)
    }
    
    static func postFriendRequest(senderUserId:Int, receiverUserId:Int) async throws -> FriendRequest {
        let url = "\(Env.BASE_URL)\(PATH_TO_FRIEND_REQUESTS)"
        let params = [
            SENDER_PARAM: senderUserId,
            RECEIVER_PARAM: receiverUserId
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterFriendRequestErrors(data: data, response: response)
        return try JSONDecoder().decode(FriendRequest.self, from: data)
    }
    
    static func deleteFriendRequest(senderUserId:Int, receiverUserId:Int) async throws {
        let endpoint = "\(Env.BASE_URL)\(PATH_TO_CUSTOM_DELETE_FRIEND_REQUEST_ENDPOINT)"
        let params = "\(SENDER_PARAM)=\(senderUserId)&\(RECEIVER_PARAM)=\(receiverUserId)"
        let url = "\(endpoint)?\(params)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterFriendRequestErrors(data: data, response: response)
    }
    
    static func deleteFriendRequest(friend_request_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_FRIEND_REQUESTS)\(friend_request_id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterFriendRequestErrors(data: data, response: response)
    }
}
