//
//  SortBy.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

struct PostFilter {
    var postType: PostType = .all
    var postTimeframe: Double = 1
}

enum PostType {
    case all, featured, matches, friends
}
