//
//  User.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

let DUMMY_USER_ID: Int = -1

protocol UserProtocol: Codable {
    var id: Int { get }
    var username: String { get }
    var first_name: String { get }
    var last_name: String { get }
    var picture: String? { get }
}

struct User: UserProtocol {
    let id: Int
    let username: String
    let first_name: String
    let last_name: String
    let picture: String?
}

struct AuthedUser: UserProtocol {
    // User properties
    let id: Int
    let username: String
    let first_name: String
    let last_name: String
    let picture: String?
    
    // AuthedUser only properties
    let email: String
    let password: String?
    var token: String?
//    let authoredPosts: [Post]
    
    init(id: Int = DUMMY_USER_ID,
         username: String,
         first_name: String,
         last_name: String,
         picture: String?,
         email: String,
         password: String,
         token: String = "",
         authoredPosts: [Post] = []){
        self.id = id
        self.username = username
        self.first_name = first_name
        self.last_name = last_name
        self.picture = picture
        self.email = email
        self.password = password
        self.token = token
//        self.authoredPosts = authoredPosts
    }
}
