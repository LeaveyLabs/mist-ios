//
//  MessageKitInfo.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/6/22.
//

import Foundation
import MessageKit

struct MessageKitInfo: MessageType {
    
    static let INFO_MESSAGE_ID = "-10"
    static let THEY_ARE_HIDDEN_MESSAGE = "The author can see your profile.\nYou can see theirs once they accept your chat request."

    // MessageType Protocol members
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var sender: SenderType
    
    var infoMessage: String
    
    init() {
        self.infoMessage = MessageKitInfo.THEY_ARE_HIDDEN_MESSAGE
        self.sender = UserService.singleton.getUserAsFrontendReadOnlyUser()
        self.kind = .custom(infoMessage)
        self.messageId = MessageKitInfo.INFO_MESSAGE_ID
        self.sentDate = Date()
    }
}
