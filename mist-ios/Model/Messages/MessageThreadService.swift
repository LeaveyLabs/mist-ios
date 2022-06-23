//
//  MessageThreadService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/22/22.
//

import Foundation

class MessageThreadService: NSObject {
    
    static var singleton = MessageThreadService()
    
    private var messageThreads: [FrontendReadOnlyUser: MessageThread] = [:]
    
    private override init(){
        super.init()
    }
    
    func loadInitialMessageThreads() throws {
        Task {
            do {
                //Get all messages
                async let sentMessages = MessageAPI.fetchMessagesBySender(sender: UserService.singleton.getId())
                async let receivedMessages = MessageAPI.fetchMessagesByReceiver(receiver: UserService.singleton.getId())
                let allMessages = try await sentMessages + receivedMessages
                
                //Organize all the messages into their respective threads
                var messageThreadsByUserIds: [Int: MessageThread] = [:]
                try allMessages.forEach { message in
                    if let messageThread = messageThreadsByUserIds[message.sender] {
                        messageThread.server_messages.append(message)
                    } else {
                        messageThreadsByUserIds[message.sender] = try MessageThread(sender: UserService.singleton.getId(),
                                                                       receiver: message.sender)
                        messageThreadsByUserIds[message.sender]!.server_messages.append(message)
                    }
                }
                         
                //Get the frontendusers (users and their profile pics) for each thread
                let users = try await UserAPI.batchFetchUsersFromUserIds(Set(Array(messageThreadsByUserIds.keys)))
                let frontendUsers = try await UserAPI.batchTurnUsersIntoFrontendUsers(users.map { $0.value })
                
                //Use Int:MessageThread and Int:FrontendUser to make FrontendUser:MessageThread
                messageThreads = Dictionary(uniqueKeysWithValues: frontendUsers.map {key, value in
                    (value, messageThreadsByUserIds[key]!)
                })
                
                //Sort the messages
                messageThreads.forEach { $0.value.server_messages.sort() }
                
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
