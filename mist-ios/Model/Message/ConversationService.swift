//
//  MessageThreadService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/22/22.
//

import Foundation

class ConversationService: NSObject {
    
    static var singleton = ConversationService()
    private var conversations = [Int: Conversation]() //[sangdaebang.id, conversation]
    
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
            
            //Get the frontendusers (users and their profile pics) for each thread
            let users = try await UserAPI.batchFetchUsersFromUserIds(Set(Array(messageThreadsByUserIds.keys)))
            let frontendUsers = try await UserAPI.batchTurnUsersIntoFrontendUsers(users.map { $0.value })
                        
            //Wait for matchRequests and blocks to load in
            try await group.waitForAll()
            
            //Create conversations with the user, messageThread, and matchRequests
            conversations = Dictionary(uniqueKeysWithValues: frontendUsers.map {userId, user in
                (userId, Conversation(sangdaebang: user, messageThread: messageThreadsByUserIds[userId]!, matchRequests: MatchRequestService.singleton.getAllUniquePostMatchRequestsWith(userId)))
            })
            
            //discard conversations where a user has blocked or been blocked
            conversations.forEach { (key: Int, value: Conversation) in
                if BlockService.singleton.isBlockedByOrHasBlocked(key) {
                    print("REMOVING VALUE VUS BLOCKED")
                    conversations.removeValue(forKey: key)
                }
            }
        }
    }
    
    var firstMessageThreadLoad = true
    func handleMessageThreadIncrease(with sangdaebangId: Int) {
        guard let newMessage = conversations[sangdaebangId]?.messageThread.server_messages.last else { return }
        guard newMessage.sender != UserService.singleton.getId() else { return }
        if firstMessageThreadLoad {
            handleReceivedMessage()
            firstMessageThreadLoad = false
        } else {
            Task {
                do {
                    try await MatchRequestService.singleton.loadMatchRequests()
                    handleReceivedMessage()
                } catch {
                    print("Couldnt get match requests alongside new message")
                }
            }
        }
    }
    
    func handleReceivedMessage() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let delegate = windowScene.delegate as? SceneDelegate, let window = delegate.window else { return }
            guard let tabVC = window.rootViewController as? UITabBarController else { return }
            let navVC = tabVC.viewControllers![2] as! UINavigationController
            let visibleChatVC = navVC.visibleViewController!
            if let chatVC = visibleChatVC as? ChatViewController {
                chatVC.messagesCollectionView.reloadData()
            } else {
                //todo later: notification creating and reading
//                        tabVC.tabBar.items![2].badgeValue = "1"
            }
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
    
    func closeConversationWith(userId: Int) {
        conversations[userId]?.matchRequests.forEach({ matchRequest in
            PostService.singleton.removePostFromConversationPosts(postId: matchRequest.post)
        })
        conversations.removeValue(forKey: userId)
    }
    
    func sendMatchRequest(to receiverUserId: Int, forPostId postId: Int) async throws {
        let newMatchRequest = try await MatchRequestService.singleton.sendMatchRequest(to: receiverUserId, for: postId)
        conversations[receiverUserId]?.matchRequests.append(newMatchRequest)
        PostService.singleton.addPostToConversationPosts(post: newMatchRequest.read_only_post!)
    }
    
    func handleNewlyBlockedUser(_ user: Int) {
        conversations.removeValue(forKey: user)
    }
    
    func handleNewlyUnblockedUser(_ user: Int) {
        //not possible with the way we've implemented blocking so far.
        //right now, if you block someone, you'll never be able to see them on the site again
        //and their content simply won't be loaded in for you
    }
    
}
