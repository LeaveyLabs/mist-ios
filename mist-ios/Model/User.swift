//
//  User.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

struct User: Codable {
    let id, email: String
    var profile: Profile
    var authoredPosts: [Post]
}
