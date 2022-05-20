//
//  Vote.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

struct Vote: Codable {
    let id: Int;
    let voter: Int;
    let post: Int;
    let timestamp: Double;
    let rating: Int;
}
