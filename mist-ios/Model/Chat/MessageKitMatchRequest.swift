//
//  MessageKitMatch.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/30/22.
//

import Foundation
import MessageKit

struct MessageKitMatchRequest: MessageType {
    // MessageType Protocol members
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var sender: SenderType
    
    // Custom members
    var matchRequest: MatchRequest
    var postTitle: String
    
    init(placeholderMatchRequest: MatchRequest, postTitle: String) {
        self.postTitle = postTitle
        self.sender = UserService.singleton.getUserAsFrontendReadOnlyUser()
        
        self.matchRequest = placeholderMatchRequest
        self.kind = .custom(matchRequest)
        self.messageId = String(matchRequest.id)
        self.sentDate = Date(timeIntervalSince1970: matchRequest.timestamp)
    }
    
    init(matchRequest: MatchRequest, conversation: Conversation) {
        self.postTitle = matchRequest.read_only_post?.title ?? MatchRequest.DELETED_POST_TITLE
        self.sender = matchRequest.match_requesting_user == UserService.singleton.getId() ? UserService.singleton.getUserAsFrontendReadOnlyUser() : conversation.sangdaebang

        self.matchRequest = matchRequest
        self.kind = .custom(matchRequest)
        self.messageId = String(matchRequest.id)
        self.sentDate = Date(timeIntervalSince1970: matchRequest.timestamp)
    }
}
