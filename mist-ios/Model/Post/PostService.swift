//
//  PostService.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation
import MapKit

class PostService: NSObject {
    
    static var initialPosts = [Post]()
    
//    static func loadInitialPosts() async throws {
//        initialPosts = try await PostAPI.fetchPosts()
//    }
//
    static func loadPostsAndUserInteractions() async throws {
        async let loadedVotes = VoteAPI.fetchVotesByUser(voter: UserService.singleton.getId())
        async let loadedFavorites = FavoriteAPI.fetchFavoritesByUser(userId: UserService.singleton.getId())
        async let loadedPosts = PostAPI.fetchPosts()
        initialPosts = try await loadedPosts
        UserService.singleton.updateUserInteractionsAfterLoadingPosts(try await loadedVotes, try await loadedFavorites)
    }
}
