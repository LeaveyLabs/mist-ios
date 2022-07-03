//
//  MessageThreadService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/22/22.
//

import Foundation

class ConversationService: NSObject {
    
    static var singleton = ConversationService()
    private var conversations = [Int: Conversation]()
    
    func loadMessageThreads() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            //Start loading MatchRequests in the background
            group.addTask { try await MatchRequestService.singleton.loadMatchRequests() }
            
            let allMessagesWithUsers = try await MessageAPI.fetchConversations()
            
            //Organize all the messages into their respective threads
            var messageThreadsByUserIds: [Int: MessageThread] = [:]
            for (userId, messages) in allMessagesWithUsers {
                messageThreadsByUserIds[userId] = try MessageThread(sender: UserService.singleton.getId(),
                                                                    receiver: userId,
                                                                    previousMessages: messages)
            }
            
            //Get the frontendusers (users and their profile pics) for each thread
            let users = try await UserAPI.batchFetchUsersFromUserIds(Set(Array(messageThreadsByUserIds.keys)))
            let frontendUsers = try await UserAPI.batchTurnUsersIntoFrontendUsers(users.map { $0.value })
                        
            //Wait for matchRequests to load in
            try await group.waitForAll()
            
            //Create conversations with the user, messageThread, and matchRequests
            conversations = Dictionary(uniqueKeysWithValues: frontendUsers.map {userId, user in
                (userId, Conversation(sangdaebang: user, messageThread: messageThreadsByUserIds[userId]!, matchRequests: MatchRequestService.singleton.getAllUniquePostMatchRequestsWith(userId)))
            })
            
//            let fakePost = PostService.singleton.getExplorePosts().first!
//            let fakeRequest = MatchRequest(id: 0, match_requesting_user: 7, match_requested_user: 1, post: fakePost.id, read_only_post: fakePost, timestamp: 0)
//            let fakeUser = users.map { FrontendReadOnlyUser(readOnlyUser: $0.value, profilePic: UIImage(named: "adam")!)}.first!
//            self.conversations = [Conversation(sangdaebang: fakeUser, messageThread: messageThreadsByUserIds[1]!, matchRequests: [])]
            

            //Register notification listeners on the size of each messageThread's server_messages
            
        }
        
    }
    
    func getCount() -> Int {
        return conversations.count
    }
    
    func getConversationAt(index: Int) -> Conversation? {
        if index < 0 || index >= conversations.count { return nil }
        return Array(conversations.values).sorted()[index]
    }
    
    func getConversationWith(userId: Int) -> Conversation? {
        return conversations[userId]
    }
    
    func openConversationWith(user: FrontendReadOnlyUser) -> Conversation? {
        do {
            let newMessageThread = try MessageThread(sender: UserService.singleton.getId(), receiver: user.id, previousMessages: [])
            let newConversation = Conversation(sangdaebang: user,
                                               messageThread: newMessageThread,
                                               matchRequests: [])
            conversations[user.id] = newConversation
            return newConversation
        } catch {
            print("This should never happen")
        }
        return nil
    }
    
    func sendMatchRequest(to receiverUserId: Int, forPostId postId: Int) async throws {
        let newMatchRequest = try await MatchRequestAPI.postMatchRequest(senderUserId: UserService.singleton.getId(), receiverUserId: receiverUserId, postId: postId)
        conversations[receiverUserId]?.matchRequests.append(newMatchRequest)
        PostService.singleton.addPostToConversationPosts(post: newMatchRequest.read_only_post!)
    }
    
    func closeConversationWith(userId: Int) {
        conversations[userId]?.matchRequests.forEach({ matchRequest in
            PostService.singleton.removePostFromConversationPosts(postId: matchRequest.post)
        })
        conversations.removeValue(forKey: userId)
    }
    
}
