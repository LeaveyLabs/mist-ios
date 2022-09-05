//
//  Mistbox.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/4/22.
//

import Foundation

struct Mistbox: Codable {
    var posts: [Post]
    var keywords: [String]
    let creation_time: Double
    var opens_used_today: Int
}
