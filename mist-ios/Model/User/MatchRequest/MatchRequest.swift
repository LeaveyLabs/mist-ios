//
//  MatchRequest.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

struct MatchRequest: Codable, Comparable {
    
    static let PLACEHOLDER_ID = -1
    static let DELETED_POST_TITLE = "mist doesn't exist"
    
    let id: Int;
    let match_requesting_user: Int;
    let match_requested_user: Int;
    let post: Int?;
    let read_only_post: Post?;
    let timestamp: Double;
    
    
    static func < (lhs: MatchRequest, rhs: MatchRequest) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
    
}
