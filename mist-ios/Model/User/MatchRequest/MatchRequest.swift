//
//  MatchRequest.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

struct MatchRequest: Codable {
    let id: Int;
    let match_requesting_user: Int;
    let match_requested_user: Int;
    let post: Int;
    let timestamp: Double;
}
