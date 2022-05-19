//
//  Comment.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/11.
//

import Foundation

struct Comment: Codable {
    let id: String;
    let uuid: String;
    let text: String;
    let timestamp: Double;
    let post: Int;
    let author: Int;
    let author_picture: String?;
    let author_username: String;
}
