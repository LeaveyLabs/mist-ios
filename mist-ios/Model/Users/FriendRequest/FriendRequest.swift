//
//  FriendRequest.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

struct FriendRequest: Codable {
    let id: Int;
    let friend_requesting_user: Int;
    let friend_requested_user: Int;
    let timestamp: Double;
}
