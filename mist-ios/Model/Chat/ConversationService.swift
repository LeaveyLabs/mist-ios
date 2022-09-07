//
//  MessageThreadService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/22/22.
//

import Foundation

struct ConversationsLastMessageReadTime: Codable {
    var lastTimestamps = [Int:Double]() //sangdaebang.id : lastReadTime
    
    enum CodingKeys: String, CodingKey {
        case lastTimestamps
    }
    
    init() {
        lastTimestamps = [:]
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lastTimestamps = try values.decodeIfPresent([Int:Double].self, forKey: .lastTimestamps) ?? [:]
    }
}

class ConversationService: NSObject {
    
    //MARK: - Properties
    
    static var singleton = ConversationService()
    private var conversationsLastMessageReadTime: ConversationsLastMessageReadTime!
    private let LOCAL_FILE_APPENDING_PATH = "conversations.json"
    private var localFileLocation: URL!
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
    
    private override init() {
        super.init()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        localFileLocation = documentsDirectory.appendingPathComponent(LOCAL_FILE_APPENDING_PATH)
        if FileManager.default.fileExists(atPath: localFileLocation.path) {
            loadFromFilesystem()
        } else {
            conversationsLastMessageReadTime = ConversationsLastMessageReadTime()
            Task { await saveToFilesystem() }
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
            
            let frontendUsers = try await UsersService.singleton.loadAndCacheUsers(userIds: Array(messageThreadsByUserIds.keys))
            
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
    
    //TODO: this system actually needs to be by user, not by device, because if i log into the same account on my iphone vs simulator, dif results emerge
    //if the user saved a read time while on here, but then logged into another device, we can't trust the read time here anymore
    func getUnreadConversations() -> [Conversation] {
        var unreadConvos = [Conversation]()
        for (sangdaebangId, convo) in nonBlockedConversations {
            guard
                let conversation = getConversationWith(userId:sangdaebangId),
                let lastMessageReceived = conversation.messageThread.server_messages.filter( {$0.sender == sangdaebangId}).last
            else { continue }
            guard let lastMessageReadTime = conversationsLastMessageReadTime.lastTimestamps[sangdaebangId] else {
                unreadConvos.append(convo) //then they've never opened a conversation with this person before
                continue
            }
            if lastMessageReadTime < lastMessageReceived.timestamp {
                unreadConvos.append(convo)
            }
        }
        print("timestamps", conversationsLastMessageReadTime.lastTimestamps)
        return unreadConvos
    }
    
    func updateLastMessageReadTime(withUserId userId: Int) {
        print("UPDATE LST MESSAGE READ TIEM")
        conversationsLastMessageReadTime.lastTimestamps[userId] = Date().timeIntervalSince1970
        Task { await saveToFilesystem() }
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

extension ConversationService {
    
    //MARK: - Filesystem
    
    func saveToFilesystem() async {
        do {
            let encoder = JSONEncoder()
            let data: Data = try encoder.encode(conversationsLastMessageReadTime)
            let jsonString = String(data: data, encoding: .utf8)!
            try jsonString.write(to: self.localFileLocation, atomically: true, encoding: .utf8)
        } catch {
            print("COULD NOT SAVE: \(error)")
        }
    }

    func loadFromFilesystem() {
        do {
            let data = try Data(contentsOf: self.localFileLocation)
            conversationsLastMessageReadTime = try JSONDecoder().decode(ConversationsLastMessageReadTime.self, from: data)
        } catch {
            print("COULD NOT LOAD: \(error)")
        }
    }
    
    func eraseData() {
        do {
            try FileManager.default.removeItem(at: self.localFileLocation)
        } catch {
            print("\(error)")
        }
    }
}
