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
    
    //MARK: - Updaters
    
    func sendFriendRequest(_ userToBeFriendedId: Int) throws {
        let newFriendRequest = FriendRequest(id: Int.random(in: 0..<Int.max), friend_requesting_user: UserService.singleton.getId(), friend_requested_user: userToBeFriendedId, timestamp: Date().timeIntervalSince1970)
        usersWhoYouFriendRequested.append(newFriendRequest)
        Task {
            do {
                let _ = try await FriendRequestAPI.postFriendRequest(senderUserId: UserService.singleton.getId(), receiverUserId: userToBeFriendedId)
            } catch {
                usersWhoYouFriendRequested.removeAll { $0.id == newFriendRequest.id }
                throw(error)
            }
        }
    }
    
    func deleteFriendRequest(_ userToBeUnFriendedId: Int) throws {
        let friedRequestToDelete = usersWhoYouFriendRequested.first { $0.friend_requested_user == userToBeUnFriendedId }!
        usersWhoYouFriendRequested.removeAll { $0.id == friedRequestToDelete.id }
        
        Task {
            do {
                let _ = try await FriendRequestAPI.deleteFriendRequest(senderUserId: UserService.singleton.getId(), receiverUserId: userToBeUnFriendedId)
            } catch {
                usersWhoYouFriendRequested.append(friedRequestToDelete)
                throw(error)
            }
        }
    }
    
}
