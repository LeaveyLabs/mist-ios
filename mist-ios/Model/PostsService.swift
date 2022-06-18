//
//  PostService.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation
import MapKit

class PostsService: NSObject {
    static var initialPosts = [Post]()
    static func loadInitialPosts() async throws {
        initialPosts = try await PostAPI.fetchPosts()
    }
}
