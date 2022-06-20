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
    let body: String //TODO: refactor to "body", since "title", "location_description" are also text, technically
    let location_description: String?
    let latitude: Double?
    let longitude: Double?
    let timestamp: Double
    let author: Int
    var votecount: Int
    var commentcount: Int
    
    //MARK: - Initializers
    
    // Post has two initializers:
    // Default initializer is used when deserializing a post from the DB
    // Custom initializer (below) is used when a user first creates a post
    
    init(id: Int = DUMMY_POST_ID,
         title: String,
         body: String,
         location_description: String?,
         latitude: Double?,
         longitude: Double?,
         timestamp: Double,
         author: Int,
         votecount: Int = 0,
         commentcount: Int = 0) {
        self.id = id
        self.title = title
        self.body = body
        self.location_description = location_description
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.author = author
        self.votecount = votecount
        self.commentcount = commentcount
    }
}
