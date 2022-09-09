//
//  Tag.swift
//  mist-ios
//
//  Created by Kevin Sun on 8/3/22.
//

import Foundation

struct Tag: Codable {
    let id: Int
    let comment: Int
    let tagged_name: String
    let tagged_user: Int? //either tagged_user or tagged_phone_number will be nil
    let tagged_phone_number: String?
    let tagging_user: Int
    let timestamp: Double
    let post: Post
}
