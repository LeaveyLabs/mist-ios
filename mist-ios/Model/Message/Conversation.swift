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
    
    //If the users have already been talking, neither profile should be hidden
    var haveUsersAlreadyBeenTalking: Bool {
        get {
            if let firstMessage = messageThread.server_messages.first, let firstMatchRequest = matchRequests.first, firstMessage.timestamp < firstMatchRequest.timestamp {
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
