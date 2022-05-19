//
//  User.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

struct User: Codable {
    let id: Int
    let email: String
    var username: String
    var first_name: String
    var last_name: String
    var profile: Profile
    var picture: String?
    var authoredPosts: [Post]
}
