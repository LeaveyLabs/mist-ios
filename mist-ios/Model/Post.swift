//
//  Post.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

struct Post: Codable {
    let id: String
    let title: String
    let text: String
    let location_description: String?
    let latitude: Double?
    let longitude: Double?
    let timestamp: Double
    let author: String
    var averagerating: Int
    var commentcount: Int
//  voteCount: Int
}
