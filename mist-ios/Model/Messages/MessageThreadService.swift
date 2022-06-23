//
//  MessageThreadService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/22/22.
//

import Foundation

class MessageThreadService: NSObject {
    
    static var singleton = MessageThreadService()
    
    private var messageThreads: [Int: MessageThread] = [:]
    
    private override init(){
        super.init()
    }
    
    func loadInitialMessageThreads() throws {
        Task {
            do {
                async let sentMessages = MessageAPI.fetchMessagesBySender(sender: UserService.singleton.getId())
                async let receivedMessages = MessageAPI.fetchMessagesByReceiver(receiver: UserService.singleton.getId())
                let allMessages = try await sentMessages + receivedMessages
                
                try allMessages.forEach { message in
                    if let messageThread = messageThreads[message.sender] {
                        messageThread.server_messages.append(message)
                    } else {
                        messageThreads[message.sender] = try MessageThread(sender: UserService.singleton.getId(),
                                                                       receiver: message.sender)
                        messageThreads[message.sender]!.server_messages.append(message)
                    }
                }
                
                messageThreads.forEach { (userId: Int, thread: MessageThread) in
                    thread.server_messages.sort()
                }
                                
                let users = try await UserAPI.batchFetchUsersFromUserIds(Set(Array(messageThreads.keys)))
                let frontendUsers = try await UserAPI.batchTurnUsersIntoFrontendUsers(users.map { $0.value })
                
                //then create MessageKitMessages
                
                //then register notification listeners on the size of each messageThread's server_messages
            }
        }
    }
    
}



class MatchRequestService: NSObject {
    
    static var singleton = MatchRequestService()
    
    private var receivedMatchRequests: [MatchRequest] = []
    private var sentMatchRequests: [MatchRequest] = []

    private override init(){
        super.init()
    }
    
    //at the start of the app, i want to call a bunch of endpoints, and then wait for all of them to finish before loading the app
    // i really wanna do this async let...
    
    func loadInitialMatches() throws {
        Task {
            do {
                async let loadedReceivedMatchRequests = MatchRequestAPI.fetchMatchRequestsByReceiver(receiverUserId: UserService.singleton.getId())
                async let loadedSentMatchRequests = MatchRequestAPI.fetchMatchRequestsBySender(senderUserId: UserService.singleton.getId())
                (receivedMatchRequests, sentMatchRequests) = try await (loadedReceivedMatchRequests, loadedSentMatchRequests)
            }
        }
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
