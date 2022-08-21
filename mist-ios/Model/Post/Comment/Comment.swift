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
    
    static let tagTextAttributes: [NSAttributedString.Key : Any] = [
//        .font: UIFont.preferredFont(forTextStyle: .body),
        .font: UIFont(name: Constants.Font.Medium, size: 16)!,
        .foregroundColor: UIColor.init(hex: "#1464a6"),
    ]
    
    static let normalTextAttributes: [NSAttributedString.Key : Any] = [
//        .font: UIFont.preferredFont(forTextStyle: .body),
        .font: UIFont(name: Constants.Font.Medium, size: 16)!,
        .foregroundColor: UIColor.black,
    ]
    
    let id: Int
    let body: String
    let timestamp: Double
    let post: Int
    let author: Int
    let read_only_author: ReadOnlyUser
    let tags: [Tag]
    
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
        self.tags = []
    }
    
    //Used when creating a comment with recently received tags
    init(comment: Comment, tags: [Tag]) {
        self.id = comment.id
        self.body = comment.body
        self.timestamp = comment.timestamp
        self.post = comment.post
        self.author = comment.author
        self.read_only_author = comment.read_only_author
        self.tags = tags
    }
}
