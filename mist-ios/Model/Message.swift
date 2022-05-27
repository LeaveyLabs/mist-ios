//
//  Message.swift
//  mist-ios
//
//  Created by Kevin Sun on 5/13/22.
//

import Foundation
import MessageKit
import UIKit

struct Message: Codable {
    let id: Int
    let sender: String
    let receiver: String
    let text: String
    let timestamp: Double?
}


// Likely no longer needed, but leave here just in case for now

//extension Message: Codable {
//
//    enum CodingKeys: String, CodingKey {
//        //MessageType
//        case user
//        case messageId
//        case sentDate
//
//        //Message
//        case from_user
//        case to_user
//        case text
//        case timestamp
//    }

//    // Explicit coders must be defined because MessageKind and SenderType are non-codable
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//
//        // MessageType
//        try container.encode(messageId, forKey: .messageId)
//        try container.encode(sentDate, forKey: .sentDate)
//        try container.encode(user, forKey: .user)
//
//        // Message
//        try container.encode(from_user, forKey: .from_user)
//        try container.encode(to_user, forKey: .to_user)
//        try container.encode(text, forKey: .text)
//        try container.encode(timestamp, forKey: .timestamp)
//    }
//
//    init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//
//        // MessageType
//        messageId = try values.decode(String.self, forKey: .messageId)
//        sentDate = try values.decode(Date.self, forKey: .sentDate)
//        user = try values.decode(User.self, forKey: .user)
//
//        // Message
//        from_user = try values.decode(String.self, forKey: .from_user)
//        to_user = try values.decode(String.self, forKey: .to_user)
//        text = try values.decode(String.self, forKey: .text)
//        timestamp = try values.decode(Int.self, forKey: .timestamp)
//    }
//}
