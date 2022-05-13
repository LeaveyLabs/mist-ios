//
//  Message.swift
//  mist-ios
//
//  Created by Kevin Sun on 5/13/22.
//

import Foundation

struct Message: Codable {
    let from_user: String;
    let to_user: String;
    let text: String;
    let timestamp: Int;
}
