//
//  Post.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation


struct Post: Codable {
    public let id, message, authorId: String;
    public let timestamp: Double
    //public let geotag: [geotag]
    public var upvotes, downvotes, flags: Int
}
