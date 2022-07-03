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
    var matchRequests: [MatchRequest]
    
    init(sangdaebang: FrontendReadOnlyUser, messageThread: MessageThread, matchRequests: [MatchRequest]) {
        self.sangdaebang = sangdaebang
        self.messageThread = messageThread
        self.matchRequests = matchRequests
        self.sort()
    }

    static func < (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.messageThread.server_messages.last! < rhs.messageThread.server_messages.last!
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.messageThread.server_messages.last! == rhs.messageThread.server_messages.last!
    }
    
    func sort() {
        //sort both the server_messages, then sort the matchrequests too
        messageThread.server_messages.sort()
    }
    
}
