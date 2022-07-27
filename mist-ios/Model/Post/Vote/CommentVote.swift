//
//  CommentVote.swift
//  mist-ios
//
//  Created by Kevin Sun on 7/26/22.
//

import Foundation

struct CommentVote: Codable {
    let id: Int;
    let voter: Int;
    let comment: Int;
    let timestamp: Double;
}
