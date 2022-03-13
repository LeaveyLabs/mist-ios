//
//  Post.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

struct Post: Codable {
    public let id: String
    public let title: String
    public let text: String
    public let location: String
    public let timestamp: Double
    public let author: String
    public let averagerating: Int
    public let commentcount: Int
//    public let voteCount: Int
}
