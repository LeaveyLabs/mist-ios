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
        let conversations = try await MessageAPI.fetchConversations()
        
        //Organize all the messages into their respective threads
        var messageThreadsByUserIds: [Int: MessageThread] = [:]
        for (userId, messages) in conversations {
            messageThreadsByUserIds[userId] = try MessageThread(sender: UserService.singleton.getId(),
                                                                receiver: userId,
                                                                previousMessages: messages)
        }
        
        //Get the frontendusers (users and their profile pics) for each thread
        let users = try await UserAPI.batchFetchUsersFromUserIds(Set(Array(messageThreadsByUserIds.keys)))

        let frontendUsers = try await UserAPI.batchTurnUsersIntoFrontendUsers(users.map { $0.value })
        self.conversations = frontendUsers.map {key, value in
            Conversation(sangdaebang: value, messageThread: messageThreadsByUserIds[key]!)
        }
        
//        let frontendUsers = users.map { FrontendReadOnlyUser(readOnlyUser: $0.value, profilePic: UIImage(named: "adam")!)}
//        self.conversations = frontendUsers.map({ user in
//            Conversation(sangdaebang: user, messageThread: messageThreadsByUserIds[user.id]!)
//        })
//
 
        
        //Sort the messages within each conversation
        self.conversations.forEach { $0.messageThread.server_messages.sort() }
        
        //Sort the conversations based on the most recent message
        self.conversations.sort()

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
            let newMessageThread = try MessageThread(sender: UserService.singleton.getId(), receiver: user.id, previousMessages: [])
            let newConversation = Conversation(sangdaebang: user, messageThread: newMessageThread)
            conversations.append(newConversation)
            return newConversation
        } catch {
            print("This should never happen")
        }
        return nil
    }
    
    func closeConversationWith(userId: Int) {
        conversations.removeAll { $0.sangdaebang.id == userId }
    }
    
}
