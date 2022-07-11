//
//  MatchRequestService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

class MatchRequestService: NSObject {
    
    static var singleton = MatchRequestService()
    
    private var receivedMatchRequests: [MatchRequest] = [] {
        didSet {
            PostService.singleton.setConversationPostIds(postIds: getAllPostUniqueMatchRequests().compactMap {$0.post})
        }
    }
    private var sentMatchRequests: [MatchRequest] = [] {
        didSet {
            PostService.singleton.setConversationPostIds(postIds: getAllPostUniqueMatchRequests().compactMap {$0.post})
        }
    }

    private override init(){
        super.init()
    }
    
    //MARK: - Loaders
    
    func loadMatchRequests() async throws {
        async let loadedReceivedMatchRequests = MatchRequestAPI.fetchMatchRequestsByReceiver(receiverUserId: UserService.singleton.getId())
        async let loadedSentMatchRequests = MatchRequestAPI.fetchMatchRequestsBySender(senderUserId: UserService.singleton.getId())
        (receivedMatchRequests, sentMatchRequests) = try await (loadedReceivedMatchRequests, loadedSentMatchRequests)
        //For each initiating match request, if the post hasn't been deleted, add it to the PostService matchRequests posts
        PostService.singleton.initializeConversationPosts(with: getAllPostUniqueMatchRequests().compactMap { $0.read_only_post })
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
    
    func getAllPostUniqueMatchRequests() -> [MatchRequest] {
        var initiatingMatchRequests = [Int: MatchRequest]() //[postId: MatchRequest]
        for matchRequest in receivedMatchRequests + sentMatchRequests {
            guard let matchRequestPostId = matchRequest.post else { continue }
            if !initiatingMatchRequests.keys.contains(matchRequestPostId) {
                initiatingMatchRequests[matchRequestPostId] = matchRequest
            }
        }
        return Array(initiatingMatchRequests.values).sorted()
    }
    
    func sendMatchRequest(to userId: Int, forPostId postId: Int?) async throws -> MatchRequest {
        if let postId = postId {
            let newMatchRequest = try await MatchRequestAPI.postMatchRequest(senderUserId: UserService.singleton.getId(), receiverUserId: userId, postId: postId)
            sentMatchRequests.append(newMatchRequest)
            return newMatchRequest
        } else {
            let newMatchRequest = try await MatchRequestAPI.postMatchRequest(senderUserId: UserService.singleton.getId(), receiverUserId: userId)
            sentMatchRequests.append(newMatchRequest)
            return newMatchRequest
        }
    }
}
