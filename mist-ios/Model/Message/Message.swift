//
//  Message.swift
//  mist-ios
//
//  Created by Kevin Sun on 5/13/22.
//

import Foundation
import MessageKit

struct Message: Codable, Comparable {
    let id: Int
    let sender: Int
    let receiver: Int
    let body: String
    let timestamp: Double
    
    static func < (lhs: Message, rhs: Message) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}


struct MessageIntermediate: Codable {
    let type: String
    let sender: Int
    let receiver: Int
    let body: String
    let token: String
}

struct ConversationStarter: Codable {
    let type: String
    let sender: Int
    let receiver: Int
}
