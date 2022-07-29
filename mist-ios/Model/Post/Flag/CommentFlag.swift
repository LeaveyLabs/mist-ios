//
//  CommentFlag.swift
//  mist-ios
//
//  Created by Kevin Sun on 7/26/22.
//

import Foundation

struct CommentFlag: Codable {
    let id: Int;
    let flagger: Int;
    let comment: Int;
    let timestamp: Double;
    let rating: Int;
}
