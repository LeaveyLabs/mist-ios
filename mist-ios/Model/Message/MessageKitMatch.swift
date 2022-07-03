//
//  MessageKitMatch.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/30/22.
//

import Foundation
import MessageKit

struct MessageKitMatch: MessageType {
    // MessageType Protocol members
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var sender: SenderType
    
    // Custom members
    var matchRequest: MatchRequest
    var postTitle: String
    
    init(matchRequest: MatchRequest, postTitle: String, matchRequester: SenderType) {
        self.matchRequest = matchRequest
        self.postTitle = postTitle
        
        self.kind = .custom(matchRequest)
        self.sender = matchRequester
        self.messageId = String(matchRequest.id)
        self.sentDate = Date(timeIntervalSince1970: matchRequest.timestamp)
    }
}
