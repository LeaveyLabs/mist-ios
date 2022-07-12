//
//  MessageThreadService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/22/22.
//

import Foundation

class ConversationService: NSObject {
    
    //MARK: - Properties
    
    static var singleton = ConversationService()
    private var conversations = [Int: Conversation]() //[sangdaebang.id, conversation]
    private var nonBlockedConversations: [Int: Conversation] {
        get {
            var nonBlockedConversations = [Int: Conversation]()
            conversations.forEach { (key: Int, value: Conversation) in
                if !BlockService.singleton.isBlockedByOrHasBlocked(key) {
                    nonBlockedConversations[key] = value
                }
            }
            return nonBlockedConversations
        }
    }
    
    
    //MARK: - Managing conversations
    
    func loadMessageThreads() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            //Start loading MatchRequests in the background
            group.addTask { try await BlockService.singleton.loadBlocks() }
            group.addTask { try await MatchRequestService.singleton.loadMatchRequests() }
            
            let allMessagesWithUsers = try await MessageAPI.fetchConversations()
            
            //Organize all the messages into their respective threads
            var messageThreadsByUserIds: [Int: MessageThread] = [:]
            for (userId, messages) in allMessagesWithUsers {
                messageThreadsByUserIds[userId] = try MessageThread(sender: UserService.singleton.getId(), receiver: userId, previousMessages: messages)
            }
            
            //Sort the server_messages
            messageThreadsByUserIds.forEach { (key: Int, value: MessageThread) in
                value.server_messages.sort()
            }
            
            //Get the frontendusers (users and their profile pics) for each thread
            let users = try await UserAPI.batchFetchUsersFromUserIds(Set(Array(messageThreadsByUserIds.keys)))
            let frontendUsers = try await UserAPI.batchTurnUsersIntoFrontendUsers(users.map { $0.value })
                        
            //Wait for matchRequests and blocks to load in
            try await group.waitForAll()
            
            //Create conversations with the user, messageThread, and matchRequests
            conversations = Dictionary(uniqueKeysWithValues: frontendUsers.map {userId, user in
                (userId, Conversation(sangdaebang: user, messageThread: messageThreadsByUserIds[userId]!))
            })
        }
    }
    
    //MARK: - Getters
    
    func getCount() -> Int {
        return nonBlockedConversations.count
    }
    
    func getConversationAt(index: Int) -> Conversation? {
        if index < 0 || index >= nonBlockedConversations.count { return nil }
        return Array(nonBlockedConversations.values).sorted()[index]
    }
    
    func getConversationWith(userId: Int) -> Conversation? {
        return nonBlockedConversations[userId]
    }
    
    //MARK: - Receiving messages
    
    func handleMessageThreadSizeIncrease(with sangdaebangId: Int) {
        guard let newMessage = conversations[sangdaebangId]?.messageThread.server_messages.last else { return }
        if newMessage.sender == UserService.singleton.getId() {
            //your message successfully sent
        } else {
            conversations[sangdaebangId]?.handleReceivedMessage(newMessage)
        }
    }
    
    //MARK: - Opening and Closing Conversations
    
    func openConversationWith(user: FrontendReadOnlyUser) -> Conversation? {
        do {
            let newMessageThread = try MessageThread(sender: UserService.singleton.getId(), receiver: user.id, previousMessages: [])
            let newConversation = Conversation(sangdaebang: user,
                                               messageThread: newMessageThread)
            conversations[user.id] = newConversation
            return newConversation
        } catch {
            print("This should never happen")
        }
        return nil
    }
    
    func closeConversationWith(userId: Int) {
        conversations.removeValue(forKey: userId)
    }
    
}
