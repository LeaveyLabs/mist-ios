//
//  Flag.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

struct PostFlag: Codable {
    let id: Int;
    let flagger: Int;
    let post: Int;
    let timestamp: Double;
    let rating: Int;
}
