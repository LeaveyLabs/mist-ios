//
//  Comment.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/11.
//

import Foundation

// Used when creating a comment
let DUMMY_COMMENT_ID: Int = -1
let DUMMY_COMMENT_TIMESTAMP: Double = 0.0
let DUMMY_COMMENT_USERNAME: String = ""

struct Comment: Codable {
    let id: Int
    let text: String
    let timestamp: Double
    let post: Int
    let author: Int
    let author_picture: String?
    let author_username: String
    
    // Used when creating a comment
    init(id: Int = DUMMY_COMMENT_ID,
         text: String,
         timestamp: Double = DUMMY_COMMENT_TIMESTAMP,
         post: Int,
         author: Int,
         author_picture: String? = nil,
         author_username: String = DUMMY_COMMENT_USERNAME) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.post = post
        self.author = author
        self.author_picture = author_picture
        self.author_username = author_username
    }
}
