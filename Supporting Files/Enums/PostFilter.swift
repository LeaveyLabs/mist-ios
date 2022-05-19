//
//  SortBy.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

struct PostFilter {
    var postType: PostType = .All
    var postTimeframe: Float = 1
}

enum PostType: String {
    case All, Featured, Matches, Friends
}
