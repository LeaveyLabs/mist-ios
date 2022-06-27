//
//  FriendRequestAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

class FriendRequestAPI {
    static let PATH_TO_FRIEND_REQUESTS = "api/friend-requests/"
    static let SENDER_PARAM = "friend_requesting_user"
    static let RECEIVER_PARAM = "friend_requested_user"
    
    static func fetchFriendRequestsBySender(senderUserId:Int) async throws -> [FriendRequest] {
        let url = "\(BASE_URL)\(PATH_TO_FRIEND_REQUESTS)?\(SENDER_PARAM)=\(senderUserId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([FriendRequest].self, from: data)
    }
    
    static func fetchFriendRequestsByReceiver(receiverUserId:Int) async throws -> [FriendRequest] {
        let url = "\(BASE_URL)\(PATH_TO_FRIEND_REQUESTS)?\(RECEIVER_PARAM)=\(receiverUserId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([FriendRequest].self, from: data)
    }
    
    static func postFriendRequest(senderUserId:Int, receiverUserId:Int) async throws -> FriendRequest {
        let url = "\(BASE_URL)\(PATH_TO_FRIEND_REQUESTS)"
        let params = [
            SENDER_PARAM: senderUserId,
            RECEIVER_PARAM: receiverUserId
        ]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(FriendRequest.self, from: data)
    }
    
    static func deleteFriendRequest(senderUserId:Int, receiverUserId:Int) async throws {
        let friendRequests = try await fetchFriendRequestsBySender(senderUserId: senderUserId)
        for friendRequest in friendRequests {
            if friendRequest.friend_requested_user == receiverUserId {
                let _ = try await deleteFriendRequest(friend_request_id: friendRequest.id)
                break
            }
        }
    }
    
    static func deleteFriendRequest(friend_request_id:Int) async throws {
        let url = "\(BASE_URL)\(PATH_TO_FRIEND_REQUESTS)\(friend_request_id)/"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
}