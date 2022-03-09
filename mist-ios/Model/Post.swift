//
//  Post.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation


struct Post: Codable {
    public let id, title, message, authorId: String;
    public let timestamp: Double
    public let location: String
    public var upvotes, downvotes, flags: Int
}
