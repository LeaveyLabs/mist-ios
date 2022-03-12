//
//  Flag.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

struct Flag: Codable {
    let id: String;
    let flagger: String;
    let post: String;
    let timestamp: Double;
    let rating: Int;
}
