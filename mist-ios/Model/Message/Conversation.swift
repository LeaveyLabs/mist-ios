//
//  Conversation.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

struct Conversation: Comparable {
    
    var sangdaebang: FrontendReadOnlyUser
    var messageThread: MessageThread
    
    static func < (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.messageThread.server_messages.last! < rhs.messageThread.server_messages.last!
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.messageThread.server_messages.last! == rhs.messageThread.server_messages.last!
    }
    
}
