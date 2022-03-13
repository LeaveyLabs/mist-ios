//
//  Comment.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/11.
//

import Foundation

struct Comment: Codable {
    let id: String;
    let text: String;
    let timestamp: Double;
    let post: String;
    let author: String;
}
