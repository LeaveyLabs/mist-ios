//
//  MatchRequestService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

class MatchRequestService: NSObject {
    
    static var singleton = MatchRequestService()
    
    private var receivedMatchRequests: [MatchRequest] = []
    private var sentMatchRequests: [MatchRequest] = []

    private override init(){
        super.init()
    }
    
    //MARK: - Loaders
    
    func loadMatchRequests() async throws {
        async let loadedReceivedMatchRequests = MatchRequestAPI.fetchMatchRequestsByReceiver(receiverUserId: UserService.singleton.getId())
        async let loadedSentMatchRequests = MatchRequestAPI.fetchMatchRequestsBySender(senderUserId: UserService.singleton.getId())
        (receivedMatchRequests, sentMatchRequests) = try await (loadedReceivedMatchRequests, loadedSentMatchRequests)
        PostService.singleton.initializeConversationPosts(with: getAllUniquePostMatchRequests().compactMap { $0.read_only_post })
    }
    
    
    //MARK: - Checkers
    
    func isMatchedWith(_ userId: Int) -> Bool {
        return hasReceivedMatchRequestFrom(userId) && hasSentMatchRequestTo(userId)
    }
    
    func hasReceivedMatchRequestFrom(_ userId: Int) -> Bool {
        return receivedMatchRequests.contains { $0.match_requesting_user == userId }
    }
    
    func hasSentMatchRequestTo(_ userId: Int) -> Bool {
        return sentMatchRequests.contains { $0.match_requested_user == userId }
    }
    
    //MARK: - Getters
    
    func getAllMatchRequestsWith(_ userId: Int) -> [MatchRequest] {
        var allMatchRequestsWithUser = [MatchRequest]()
        for receivedMatchRequest in receivedMatchRequests {
            if receivedMatchRequest.match_requesting_user == userId {
                allMatchRequestsWithUser.append(receivedMatchRequest)
            }
        }
        for sentMatchRequest in sentMatchRequests {
            if sentMatchRequest.match_requested_user == userId {
                allMatchRequestsWithUser.append(sentMatchRequest)
            }
        }
        return allMatchRequestsWithUser
    }
    
    func getAllUniquePostMatchRequestsWith(_ userId: Int) -> [MatchRequest] {
        var allUniqueMatchRequestsWithUser = [Int: MatchRequest]() //[postId: MatchRequest]
        for matchRequest in getAllMatchRequestsWith(userId) {
            if !allUniqueMatchRequestsWithUser.keys.contains(matchRequest.post) {
                allUniqueMatchRequestsWithUser[matchRequest.post] = matchRequest
            }
        }
        return Array(allUniqueMatchRequestsWithUser.values)
    }
    
    func getAllUniquePostMatchRequests() -> [MatchRequest] {
        var allUniqueMatchRequests = [Int: MatchRequest]() //[postId: MatchRequest]
        for matchRequest in receivedMatchRequests + sentMatchRequests {
            if !allUniqueMatchRequests.keys.contains(matchRequest.post) {
                allUniqueMatchRequests[matchRequest.post] = matchRequest
            }
        }
        return Array(allUniqueMatchRequests.values)
    }
}
