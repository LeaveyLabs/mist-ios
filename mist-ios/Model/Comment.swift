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
    let body: String
    let timestamp: Double
    let post: Int
    let author: Int
    let read_only_author: ReadOnlyUser
    
    // Used when creating a comment
    init(id: Int = DUMMY_COMMENT_ID,
         body: String,
         timestamp: Double = DUMMY_COMMENT_TIMESTAMP,
         post: Int) {
        self.id = id
        self.body = body
        self.timestamp = timestamp
        self.post = post
        self.author = UserService.singleton.getId()
        self.read_only_author = UserService.singleton.getUserAsReadOnlyUser()
    }
}
