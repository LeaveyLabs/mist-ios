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
        
        //for setting up fake data
//        if let first = sentMatchRequests.first {
//            try await MatchRequestAPI.deleteMatchRequest(match_request_id: first.id)
//            sentMatchRequests.remove(at: 0)
//        }
//        let fakePost = try await PostAPI.fetchPosts().first!
//        let fakeRequest = MatchRequest(id: 0, match_requesting_user: 1, match_requested_user: 7, post: fakePost.id, read_only_post: fakePost, timestamp: Date().timeIntervalSince1970)
//        receivedMatchRequests.append(fakeRequest)
        
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
        return allMatchRequestsWithUser.sorted()
    }
    
    func getInitiatingMatchRequestsWith(_ userId: Int) -> [MatchRequest] {
        var initiatingMatchRequests = [Int: MatchRequest]() //[postId: MatchRequest]
        for matchRequest in getAllMatchRequestsWith(userId) {
            if !initiatingMatchRequests.keys.contains(matchRequest.post) {
                initiatingMatchRequests[matchRequest.post] = matchRequest
            }
        }
        return Array(initiatingMatchRequests.values).sorted()
    }
    
    func getAllUniquePostMatchRequests() -> [MatchRequest] {
        var allUniqueMatchRequests = [Int: MatchRequest]() //[postId: MatchRequest]
        for matchRequest in receivedMatchRequests + sentMatchRequests {
            if !allUniqueMatchRequests.keys.contains(matchRequest.post) {
                allUniqueMatchRequests[matchRequest.post] = matchRequest
            }
        }
        return Array(allUniqueMatchRequests.values).sorted()
    }
    
    func sendMatchRequest(to userId: Int, forPostId postId: Int) async throws -> MatchRequest {
        let newMatchRequest = try await MatchRequestAPI.postMatchRequest(senderUserId: UserService.singleton.getId(), receiverUserId: userId, postId: postId)
        sentMatchRequests.append(newMatchRequest)
        return newMatchRequest
    }
}
