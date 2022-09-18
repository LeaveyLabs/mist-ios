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
        startOccasionalRefreshTask()
    }
    
    
    //MARK: - Managing conversations
    
    func loadInitialMessageThreads() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            //Start loading MatchRequests in the background
            group.addTask { try await BlockService.singleton.loadBlocks() }
            group.addTask { try await MatchRequestService.singleton.loadMatchRequests() }
            
            //Wait for matchRequests and blocks to load in, because our conversations depend on loaded matchRequest in initialziation
            try await group.waitForAll()
            
            try await prepareConversations()
        }
    }
    
    //make server messages thread safe
    //on reconnect.... what if we got new messages while we were disconnected?
    //also, whenever receiving/sending a message, make sure all the messages are as they should be
    
    func loadMatchRequestsAndCreateNewConversations() async throws {
        try await MatchRequestService.singleton.loadMatchRequests()
        let matchRequestsWithoutConvos = MatchRequestService.singleton.getAllPostUniqueMatchRequests().filter {
            conversations[$0.match_requested_user] == nil && conversations[$0.match_requesting_user] == nil
        }
        guard !matchRequestsWithoutConvos.isEmpty else { return }

        let userIdsToCreateConvosWith = matchRequestsWithoutConvos.map {
            $0.match_requested_user == UserService.singleton.getId() ? $0.match_requesting_user : $0.match_requested_user
        }
        
        try await prepareConversations(onlyWithUserIds: userIdsToCreateConvosWith)
        
        forceVisualConversationsReload()
    }
    
    func prepareConversations(onlyWithUserIds: [Int]? = nil) async throws {
        let allMessagesWithUsers = try await MessageAPI.fetchConversations()
        var newMessageThreadsByUserIds: [Int: MessageThread] = [:]
        if let onlyWithUserIds = onlyWithUserIds {
            for userId in onlyWithUserIds {
                guard let newMessages = allMessagesWithUsers[userId] else { continue }
                newMessageThreadsByUserIds[userId] = try MessageThread(sender: UserService.singleton.getId(), receiver: userId, previousMessages: newMessages)
            }
        } else {
            for (userId, newMessages) in allMessagesWithUsers {
                newMessageThreadsByUserIds[userId] = try MessageThread(sender: UserService.singleton.getId(), receiver: userId, previousMessages: newMessages)
            }
        }
        newMessageThreadsByUserIds.forEach { $1.server_messages.sort() }
        
        let frontendUsers = try await UsersService.singleton.loadAndCacheEverythingForUsers(userIds: Array(newMessageThreadsByUserIds.keys))
        let profilePics = try await UsersService.singleton.loadAndCacheProfilePics(users: frontendUsers.map { $0.value })
        //Create conversations with the user, messageThread, and matchRequests
//        conversations = Dictionary(uniqueKeysWithValues: frontendUsers.map {userId, user in
//            (userId, Conversation(sangdaebang: user, messageThread: newMessageThreadsByUserIds[userId]!))
//        }) //not safe:: we don't want to overwrite existing conversations
        frontendUsers.forEach { userId, user in
            conversations[userId] = Conversation(sangdaebang: user, messageThread: newMessageThreadsByUserIds[userId]!)
        }
        conversations.forEach { $1.sangdaebang.profilePic = profilePics[$0] }
    }
    
    func forceVisualConversationsReload() {
        DispatchQueue.main.async {
            guard let tabVC = UIApplication.shared.windows.first?.rootViewController as? SpecialTabBarController else { return }
            tabVC.refreshBadgeCount()
            let visibleVC = SceneDelegate.visibleViewController
            if let conversationsVC = visibleVC as? ConversationsViewController {
                conversationsVC.tableView.reloadData()
            }
        }
    }
    
    func startOccasionalRefreshTask() {
        Task {
            while true {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 10)
                conversations.forEach { userId, convo in
                    convo.messageThread.refreshSocketStatus()
                }
                try await loadMatchRequestsAndCreateNewConversations()
            }
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
    
    func getUnreadConversations() -> [Conversation] {
        var unreadConvos = [Conversation]()
        for (sangdaebangId, convo) in nonBlockedConversations {
            guard
                let conversation = getConversationWith(userId:sangdaebangId),
                let lastMessageReceived = conversation.messageThread.server_messages.filter( {$0.sender == sangdaebangId}).last
            else { continue }
            guard let lastMessageReadTime = conversationsLastMessageReadTime.lastTimestamps[sangdaebangId] else {
                unreadConvos.append(convo) //they've never opened a conversation with this person before
                continue
            }
            if lastMessageReadTime < lastMessageReceived.timestamp {
                unreadConvos.append(convo)
            }
        }
        return unreadConvos
    }
    
    func updateLastMessageReadTime(withUserId userId: Int) {
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
    
    func openConversationWith(user: ThumbnailReadOnlyUser) -> Conversation? {
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
