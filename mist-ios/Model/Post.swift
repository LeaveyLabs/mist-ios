//
//  Post.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

let DUMMY_POST_ID: Int = -1

struct Post: Codable, Equatable {
    let id: Int
    let title: String
    let text: String //TODO: consider changing to "body"
    let location_description: String?
    let latitude: Double?
    let longitude: Double?
    let timestamp: Double
    let author: Int
    let averagerating: Int
    let commentcount: Int
//  voteCount: Int
    
    //MARK: - Initializers
    
    // Post has two initializers:
    // Default initializer is used when deserializing a post from the DB
    // Custom initializer (below) is used when a user first creates a post
    
    init(id: Int = DUMMY_POST_ID,
         title: String,
         text: String,
         location_description: String?,
         latitude: Double?,
         longitude: Double?,
         timestamp: Double,
         author: Int,
         averagerating: Int = 0,
         commentcount: Int = 0) {
        self.id = id
        self.title = title
        self.text = text
        self.location_description = location_description
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.author = author
        self.averagerating = averagerating
        self.commentcount = commentcount
    }
}
