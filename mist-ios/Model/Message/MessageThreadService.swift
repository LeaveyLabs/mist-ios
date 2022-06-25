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
    
    func loadMessageThreads() async throws {
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
    
    func getConversationWith(userId: Int) -> Conversation? {
        if let pair = messageThreads.first(where: { $0.key.id == userId }) {
            return Conversation(sangdaebang: pair.key, messageThread: pair.value)
        } else {
            return nil
        }
    }
    
    func openConversationWith(user: FrontendReadOnlyUser) -> Conversation? {
        do {
            let newMessageThread = try MessageThread(sender: UserService.singleton.getId(), receiver: user.id)
            messageThreads[user] = newMessageThread
            return Conversation(sangdaebang: user, messageThread: newMessageThread)
        } catch {
            print("This should never happen")
        }
        return nil
    }
    
}
