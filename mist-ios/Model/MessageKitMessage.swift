//
//  MessageKitMessage.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/16.
//

import Foundation
import MessageKit

struct MessageKitMessage: MessageType {
    // MessageType Protocol members
    var user: MessageKitUser
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var sender: SenderType {
        return user
    }
    
    // Custom members
    var message: Message
    
    init(text: String, messageKitUser: MessageKitUser, messageId: String, date: Date) {
        self.kind = .attributedText(NSAttributedString(string: text))
        self.user = messageKitUser
        self.messageId = messageId
        self.sentDate = date
        
        message = Message(id: Int(messageId)!,
                          sender: messageKitUser.senderId,
                          receiver: "UPDATE",
                          text: text,
                          timestamp: date.timeIntervalSince1970)
    }
}
