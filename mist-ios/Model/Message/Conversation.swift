//
//  Conversation.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation
import MessageKit

//Note: Conversation is a class because of the assumption that can will only ever be one conversation loaded into the screen at any given point in time
class Conversation {
    
    //MARK: - Properties
    
    //Data
    var sangdaebang: FrontendReadOnlyUser
    var messageThread: MessageThread
    var initiatingMatchRequests: [MatchRequest] {
        get {
            return MatchRequestService.singleton.getInitiatingMatchRequestsWith(sangdaebang.id)
        }
    }

    var chatObjects = [MessageType]()
    var placeholderMessageKitMatchRequest: MessageKitMatchRequest?
    
    let RENDER_MORE_MESSAGES_INTERVAL = 50
    var renderedIndex: Int!
    
    //Flags
    //If the users have already been talking, neither profile should be hidden
    var haveUsersAlreadyBeenTalking: Bool {
        get {
            if let firstMessage = messageThread.server_messages.first, let firstMatchRequest = initiatingMatchRequests.first, firstMessage.timestamp < firstMatchRequest.timestamp {
                return true
            }
            return false
        }
    }
    //They are hidden until you receive a message from them.
    var isSangdaebangHidden: Bool {
        get {
            return !MatchRequestService.singleton.hasReceivedMatchRequestFrom(sangdaebang.id) && !haveUsersAlreadyBeenTalking
        }
    }
    //The only case you're hidden is if you received a message from them but haven't accepted it yet.
    var isAuthedUserHidden: Bool {
        get {
            return MatchRequestService.singleton.hasReceivedMatchRequestFrom(sangdaebang.id) && !MatchRequestService.singleton.hasSentMatchRequestTo(sangdaebang.id) && !haveUsersAlreadyBeenTalking
        }
    }
    
    //MARK: - Initialization
    
    init(sangdaebang: FrontendReadOnlyUser, messageThread: MessageThread) {
        self.sangdaebang = sangdaebang
        self.messageThread = messageThread
        let messageKitMatchRequests = initiatingMatchRequests.map { MessageKitMatchRequest(matchRequest: $0, conversation: self) }
        let messageKitMessages = messageThread.server_messages.map { MessageKitMessage(message: $0, conversation: self) }
        self.chatObjects = messageKitMessages + messageKitMatchRequests
        chatObjects.sort { $0.sentDate < $1.sentDate }
        renderedIndex = min(50, chatObjects.count)
    }
    
    //MARK: - Setup
    
    func openConversationFromPost(postId: Int, postTitle: String) {
        placeholderMessageKitMatchRequest = nil
        if !initiatingMatchRequests.contains(where: { $0.post == postId }) {
            let placeholderMatchRequest = MatchRequest(id: MatchRequest.PLACEHOLDER_ID, match_requesting_user: UserService.singleton.getId(), match_requested_user: sangdaebang.id, post: postId, read_only_post: nil, timestamp: Date().timeIntervalSince1970)
            placeholderMessageKitMatchRequest = MessageKitMatchRequest(placeholderMatchRequest: placeholderMatchRequest, postTitle: postTitle)
        }
        renderedIndex = min(50, chatObjects.count)
    }
    
    func openConversation() {
        placeholderMessageKitMatchRequest = nil
        renderedIndex = min(50, chatObjects.count)
    }
    
    //MARK: - Getters
        
    func getRenderedChatObjects() -> [MessageType] {
        var allChatObjects = Array(chatObjects.suffix(renderedIndex))
        if let placeholderMessageKitMatchRequest = placeholderMessageKitMatchRequest {
            allChatObjects.insert(placeholderMessageKitMatchRequest, at: 0)
        }
        if isSangdaebangHidden {
            allChatObjects.insert(MessageKitInfo(), at: 0)
        }
        return allChatObjects
    }
    
    func hasRenderedAllChatObjects() -> Bool {
        return renderedIndex == chatObjects.count
    }
    
    func userWantsToSeeMoreMessages() {
        renderedIndex = min(renderedIndex + RENDER_MORE_MESSAGES_INTERVAL, chatObjects.count)
    }
        
    //MARK: - Sending things
    
    func sendInitiatingMatchRequest(forPostId postId: Int) async throws {
        let newMatchRequest = try await MatchRequestService.singleton.sendMatchRequest(to: sangdaebang.id, forPostId: postId)
        chatObjects.append(MessageKitMatchRequest(matchRequest: newMatchRequest, conversation: self))
        placeholderMessageKitMatchRequest = nil
        PostService.singleton.addPostToConversationPosts(post: newMatchRequest.read_only_post!)
    }
    
    func sendAcceptingMatchRequest() async throws {
        let mostRecentMatchRequest = initiatingMatchRequests.last!
        let _ = try await MatchRequestService.singleton.sendMatchRequest(to: sangdaebang.id, forPostId: mostRecentMatchRequest.post)
    }
    
    func sendMessage(messageText: String) async throws {
        if let placeholderMatchRequest = placeholderMessageKitMatchRequest {
            try await sendInitiatingMatchRequest(forPostId: placeholderMatchRequest.matchRequest.post)
            renderedIndex += 1
        }
                
        do {
            try messageThread.sendMessage(message_text: messageText)
            let attributedMessage = NSAttributedString(string: messageText, attributes: [.font: UIFont(name: Constants.Font.Medium, size: 15)!])
            let messageKitMessage = MessageKitMessage(text: attributedMessage,
                                            sender: UserService.singleton.getUserAsFrontendReadOnlyUser(),
                                                      receiver: sangdaebang,
                                            messageId: String(Int.random(in: 0..<Int.max)),
                                            date: Date())
            chatObjects.append(messageKitMessage)
            renderedIndex += 1
        } catch {
            //TODO: delete match request on the server and remove the most recent chatObject
        }
    }
    
    //MARK: - Receiving things
    
    func handleReceivedMessage(_ message: Message) {
        let attributedMessage = NSAttributedString(string: message.body, attributes: [.font: UIFont(name: Constants.Font.Medium, size: 15)!])
        let messageKitMessage = MessageKitMessage(text: attributedMessage, sender: sangdaebang, receiver: UserService.singleton.getUserAsFrontendReadOnlyUser(), messageId: String(message.id), date: Date(timeIntervalSince1970: message.timestamp))
        chatObjects.append(messageKitMessage)
        renderedIndex += 1
        Task {
            do {
                try await MatchRequestService.singleton.loadMatchRequests()
                let newMatchRequest = initiatingMatchRequests.first(where: { $0.timestamp > chatObjects.last?.sentDate.timeIntervalSince1970 ?? 0 })
                if let newMatchRequest = newMatchRequest {
                    chatObjects.append(MessageKitMatchRequest(matchRequest: newMatchRequest, conversation: self))
                    renderedIndex += 1
                }
                DispatchQueue.main.async {
                    let visibleVC = SceneDelegate.visibleViewController
                    if let chatVC = visibleVC as? ChatViewController {
                        chatVC.handleNewMessage()
                    } else if let conversationsVC = visibleVC as? ConversationsViewController {
                        conversationsVC.tableView.reloadData()
                        //add a notification here, too
                    } else {
                        //todo later: notification creating and reading
        //                        tabVC.tabBar.items![2].badgeValue = "1"
                    }
                }
            } catch {
                print("Couldnt get match requests alongside new message")
            }
        }
    }
    
}

//MARK: - Comparable

extension Conversation: Comparable {
    
    //The first conversations should be the ones with the largest dates
    static func < (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.chatObjects.last!.sentDate > rhs.chatObjects.last!.sentDate
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.chatObjects.last!.sentDate == rhs.chatObjects.last!.sentDate
    }

}


//If two messages are both attributedText, then their messageKind is equal
//extension MessageKind: Equatable {
//    public static func == (lhs: MessageKind, rhs: MessageKind) -> Bool {
//        switch (lhs, rhs) {
//        case (.attributedText(_), .attributedText(_)):
//            return true
//        case (.custom(_), .custom(_)):
//            return true
//        default:
//            return false
//        }
//    }
//}
