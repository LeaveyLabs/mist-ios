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
    
    func loadMatchRequests() async throws {
        async let loadedReceivedMatchRequests = MatchRequestAPI.fetchMatchRequestsByReceiver(receiverUserId: UserService.singleton.getId())
        async let loadedSentMatchRequests = MatchRequestAPI.fetchMatchRequestsBySender(senderUserId: UserService.singleton.getId())
        (receivedMatchRequests, sentMatchRequests) = try await (loadedReceivedMatchRequests, loadedSentMatchRequests)
    }
    
    func isMatchedWith(_ userId: Int) -> Bool {
        return hasReceivedMatchRequestFrom(userId) && hasSentMatchRequestTo(userId)
    }
    
    func hasReceivedMatchRequestFrom(_ userId: Int) -> Bool {
        return receivedMatchRequests.contains { $0.match_requesting_user == userId }
    }
    
    func hasSentMatchRequestTo(_ userId: Int) -> Bool {
        return sentMatchRequests.contains { $0.match_requested_user == userId }
    }
}
