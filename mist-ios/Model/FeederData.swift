//
//  FeederData.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/5/22.
//

import Foundation

struct FeederData {
    
    static let posts: [Post] = [
        Post(id: 1,
             title: "That crazy",
             body: "omgggggg  youre sooooo cute",
             location_description: nil,
             latitude: nil,
             longitude: nil,
             timestamp: 10298,
             author: 0,
             commentcount: 0),
        Post(id: 2,
             title: "hiiiiiiiii",
             body: "omgggggg  youre sooooo cute",
             location_description: nil,
             latitude: nil,
             longitude: nil,
             timestamp: 10298,
             author: 0,
             commentcount: 0),
        Post(id: 3,
             title: "tommy trojans yooooooooooooo",
             body: "omgggggg  youre sooooo cute",
             location_description: nil,
             latitude: nil,
             longitude: nil,
             timestamp: 10298,
             author: 0,
             commentcount: 0),
        Post(id: 4,
             title: " a;lsdkjf  dfl;kd;f  sfdsfkljs dl s s d",
             body: "omgggggg  youre sooooo cute",
             location_description: nil,
             latitude: nil,
             longitude: nil,
             timestamp: 10298,
             author: 0,
             commentcount: 0)]
        
    static let users: [FrontendReadOnlyUser] = [
        FrontendReadOnlyUser(
            readOnlyUser: ReadOnlyUser(badges: [], id: 0,
                                       username: "adamvnovak",
                                       first_name: "Adam",
                                       last_name: "Novak",
                                       picture: "asdfasdfadsf"),
            profilePic: UIImage(named: "adam")!),
        FrontendReadOnlyUser(
            readOnlyUser: ReadOnlyUser(badges: [], id: 0,
                                       username: "prav",
                                       first_name: "Pranav",
                                       last_name: "Sav",
                                       picture: "asdfasdfadsf"),
            profilePic: UIImage(named: "pic1")!),
        FrontendReadOnlyUser(
            readOnlyUser: ReadOnlyUser(badges: [], id: 0,
                                       username: "googo",
                                       first_name: "Sooyeon",
                                       last_name: "Go",
                                       picture: "asdfasdfadsf"),
            profilePic: UIImage(named: "pic2")!),
        FrontendReadOnlyUser(
            readOnlyUser: ReadOnlyUser(badges: [], id: 0,
                                       username: "lit",
                                       first_name: "Little",
                                       last_name: "Boy",
                                       picture: "asdfasdfadsf"),
            profilePic: UIImage(named: "pic3")!),
        FrontendReadOnlyUser(
            readOnlyUser: ReadOnlyUser(badges: [], id: 0,
                                       username: "asdf",
                                       first_name: "Jack",
                                       last_name: "Novak",
                                       picture: "asdfasdfadsf"),
            profilePic: UIImage(named: "pic4")!),]
    
    static let comments: [Comment] = [
        Comment(id: 0,
                body: "this is a comment",
                timestamp: 102020,
                post: 0)]
}
