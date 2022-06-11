//
//  Favorite.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

struct Favorite: Codable {
    let id: Int;
    let timestamp: Double;
    let post: Int;
    let favoriting_user: Int;
}
