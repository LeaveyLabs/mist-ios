//
//  Block.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

struct Block: Codable {
    let id: Int;
    let blocked_user: Int;
    let blocking_user: Int;
    let timestamp: Double;
}
