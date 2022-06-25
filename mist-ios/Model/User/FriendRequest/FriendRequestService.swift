//
//  FriendRequestService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

class FriendRequestService: NSObject {
    
    static var singleton = FriendRequestService()
    
    private var usersWhoYouFriendRequested: [FriendRequest] = []
    private var usersWhoFriendRequestedYou: [FriendRequest] = []

    private override init(){
        super.init()
    }
    
    func loadFriendRequests() async throws {
        async let loadedUsersWhoYouFriendRequested = FriendRequestAPI.fetchFriendRequestsBySender(senderUserId: UserService.singleton.getId())
        async let loadedUsersWhoFriendRequestedYou = FriendRequestAPI.fetchFriendRequestsByReceiver(receiverUserId: UserService.singleton.getId())
        (usersWhoYouFriendRequested, usersWhoFriendRequestedYou) = try await (loadedUsersWhoYouFriendRequested, loadedUsersWhoFriendRequestedYou)
    }
    
    func hasBeenRequestedBy(_ userId: Int) -> Bool {
        return usersWhoFriendRequestedYou.contains { $0.friend_requesting_user == userId }
    }
    
    func hasRequested(_ userId: Int) -> Bool {
        return usersWhoYouFriendRequested.contains { $0.friend_requested_user == userId }
    }
    
    func isBlockedByOrHasBlocked(_ userId: Int) -> Bool {
        return hasRequested(userId) || hasBeenRequestedBy(userId)
    }
}
