//
//  MessageThreadService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/22/22.
//

import Foundation

class ConversationService: NSObject {
    
    static var singleton = ConversationService()
    
    private var conversations: [Conversation] = []
    
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
        
        conversations = frontendUsers.map {key, value in
            Conversation(sangdaebang: value, messageThread: messageThreadsByUserIds[key]!)
        }
        
        //Sort the messages within each conversation
        conversations.forEach { $0.messageThread.server_messages.sort() }
        
        //Sort the conversations based on the most recent message
        conversations.sort()
        
        //then register notification listeners on the size of each messageThread's server_messages
    }
    
    func getCount() -> Int {
        return conversations.count
    }
    
    func getAllConversations() -> [Conversation] {
        return conversations
    }
    
    func getConversationAt(index: Int) -> Conversation? {
        if index < 0 || index >= conversations.count { return nil }
        return conversations[index]
    }
    
    func getConversationWith(userId: Int) -> Conversation? {
        return conversations.first(where: { $0.sangdaebang.id == userId })
    }
    
    func openConversationWith(user: FrontendReadOnlyUser) -> Conversation? {
        do {
            let newMessageThread = try MessageThread(sender: UserService.singleton.getId(), receiver: user.id)
            return Conversation(sangdaebang: user, messageThread: newMessageThread)
        } catch {
            print("This should never happen")
        }
        return nil
    }
    
    func closeConversationWith(userId: Int) {
        conversations.removeAll { $0.sangdaebang.id == userId }
    }
    
}
