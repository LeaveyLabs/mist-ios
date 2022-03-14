//
//  User.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

struct User: Codable {
    let id, email: String;
    var username, firstName, lastName: String;
    var authoredPosts: [Post];

//    //creating a new user
//    init(id: String, username: String, email: String, first_name: String, last_name: String) {
//        self.id = id;
//        self.username = username;
//        self.email = email;
//        self.first_name = "";
//        self.last_name = ""
//        self.authored_posts = [];
//    }
//
//    //loading in an existing user
//    init(id: String, username: String, email: String, first_name: String, last_name: String, authored_posts: [Post]) {
//        self.id = id;
//        self.username = username;
//        self.email = email;
//        self.first_name = "";
//        self.last_name = ""
//        self.authored_posts = authored_posts;
//    }

//    //MARK: - getters
//
//    func getID() -> String {
//        return ID;
//    }
//
//    func getUsername() -> String {
//        return username;
//    }
//
//    func getEmail() -> String {
//        return email;
//    }
//
//    func getLastName() -> String {
//        return last_name;
//    }
//
//    func getFirstName() -> String {
//        return first_name;
//    }
//
//    func getAuthoredPosts() -> [Post]? {
//        return authored_posts;
//    }
//
//    //MARK: - setters
//
//    mutating func setUsername(to newUseranme: String)  {
//        self.username = newUseranme;
//    }
//
//    mutating func setEmail(to newEmail: String)  {
//        self.email = newEmail
//    }
//
//    mutating func setLastName(to newLastName: String)  {
//        self.last_name = newLastName
//    }
//
//    mutating func setFirstName(to newFirstName: String)  {
//        self.first_name = newFirstName
//    }
//
//    mutating func setAuthoredPosts(to newAuthoredPosts: [Post])  {
//        self.authored_posts = newAuthoredPosts
//    }
}
