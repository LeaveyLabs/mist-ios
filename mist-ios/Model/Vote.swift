//
//  Vote.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

struct Vote: Codable {
    let id: String;
    let voter: String;
    let post: String;
    let timestamp: Double;
    let rating: Int;
}
