//
//  PostService.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation
import MapKit

class PostService: NSObject {
    
    static var singleton = PostService()
    
    private var explorePosts = [Int: Post]() //[postId: post]
    private var sortedExplorePosts = [Post]() {
        didSet {
            explorePosts = Dictionary(uniqueKeysWithValues: sortedExplorePosts.map { ($0.id, $0) })
        }
    }
    private var conversationPosts = [Int: Post]()
    private var submissions = [Int: Post]()
    private var favorites = [Int: Post]()
    private var mentions = [Int: Post]()
    
    private var explorePostFilter = PostFilter()
    
    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    //MARK: - Load and setup
    
    func loadPosts() async throws {
        switch explorePostFilter.searchBy {
        case .all:
            sortedExplorePosts = try await PostAPI.fetchPosts()
        case .location:
            sortedExplorePosts = try await PostAPI.fetchPostsByLatitudeLongitude(latitude: explorePostFilter.region.center.latitude, longitude: explorePostFilter.region.center.longitude, radius: convertLatDeltaToKms(explorePostFilter.region.span.latitudeDelta))
        case .text:
            sortedExplorePosts = try await PostAPI.fetchPostsByWords(words: [explorePostFilter.text ?? ""])
        }
    }
    
    func initializeConversationPosts(with posts: [Post]) {
        conversationPosts = Dictionary(uniqueKeysWithValues: posts.map { ($0.id, $0) })
    }
    
    //MARK: - Update posts
    
    func updateAllPostsWithDataFrom(updatedPost: Post) {
        if !explorePosts.keys.contains(updatedPost.id) { explorePosts[updatedPost.id] = updatedPost }
        if !conversationPosts.keys.contains(updatedPost.id) { conversationPosts[updatedPost.id] = updatedPost }
        if !submissions.keys.contains(updatedPost.id) { submissions[updatedPost.id] = updatedPost }
        if !favorites.keys.contains(updatedPost.id) { favorites[updatedPost.id] = updatedPost }
        if !mentions.keys.contains(updatedPost.id) { mentions[updatedPost.id] = updatedPost }
        rerenderAnyVisiblePosts()
    }
    
    func rerenderAnyVisiblePosts() {
        //for each tab bar index, get the top view controller
        //if there is a post displayed somewhere on that view controller, call its "rerender posts" function
    }
    
    //MARK: - Getting
    
    func getExplorePosts() -> [Post] {
        return sortedExplorePosts
    }
    
    func getExploreFilter() -> PostFilter {
        return explorePostFilter
    }
    
    func getConversationPost(postId: Int) -> Post? {
        return conversationPosts[postId] //even though the convesation around a post exists, the post might have been deleted at any point in time by the user
    }
    
    //MARK: - Update filter
    
    func resetFilter() {
        explorePostFilter = .init()
    }
    
    func updateFilter(newPostFilter: PostFilter) {
        explorePostFilter = newPostFilter
    }
    
    func updateFilter(newText: String?) {
        explorePostFilter.text = newText
    }
    
    func updateFilter(newTimeframe: Float) {
        explorePostFilter.postTimeframe = newTimeframe
    }
    
    func updateFilter(newPostType: PostType) {
        explorePostFilter.postType = newPostType
    }
    
    func updateFilter(newSearchBy: SearchBy) {
        explorePostFilter.searchBy = newSearchBy
    }
    
    func updateFilter(newRegion: MKCoordinateRegion) {
        explorePostFilter.region = newRegion
    }
    
    //MARK: - Upload
    
    func uploadPost(title: String,
                    text: String,
                    locationDescription: String?,
                    latitude: Double?,
                    longitude: Double?,
                    timestamp: Double) async throws -> Post {
        // DB update
        let newPost = try await PostAPI.createPost(title: title,
                                                   text: text,
                                                   locationDescription: locationDescription,
                                                   latitude: latitude,
                                                   longitude: longitude,
                                                   timestamp: timestamp,
                                                   author: UserService.singleton.getId())
        return newPost
        
        //TODO: we really shouldnt be returning this. we should insert it into submissions and into explorePosts
    }
    
    func addPostToConversationPosts(post: Post) {
        conversationPosts[post.id] = post
    }
    
    func removePostFromConversationPosts(postId: Int) {
        conversationPosts.removeValue(forKey: postId)
    }
    
    //MARK: - Delete
    
    func deletePost(postId: Int) async throws {
        try await PostAPI.deletePost(post_id: postId)
        
        explorePosts.removeValue(forKey: postId)
        conversationPosts.removeValue(forKey: postId)
        submissions.removeValue(forKey: postId)
        favorites.removeValue(forKey: postId)
        mentions.removeValue(forKey: postId)
        
        rerenderAnyVisiblePosts()
    }
    
}
