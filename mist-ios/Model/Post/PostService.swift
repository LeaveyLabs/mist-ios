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
    
    private var allLoadedPosts = [Int: Post]() //[postId: post]
    
    private var explorePostIds = [Int]()
    private var conversationPostIds = [Int]()
    private var submissionIds = [Int]()
    private var favoriteIds = [Int]()
//    private var mentions = [Int]()
    
    private var explorePostFilter = PostFilter()
    
    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    //MARK: - Load and setup
        
    func loadExplorePosts() async throws {
        var loadedPosts = [Post]()
        switch explorePostFilter.searchBy {
        case .all:
            loadedPosts = try await PostAPI.fetchPosts()
        case .location:
            loadedPosts = try await PostAPI.fetchPostsByLatitudeLongitude(latitude: explorePostFilter.region.center.latitude, longitude: explorePostFilter.region.center.longitude, radius: convertLatDeltaToKms(explorePostFilter.region.span.latitudeDelta))
        case .text:
            loadedPosts = try await PostAPI.fetchPostsByWords(words: [explorePostFilter.text ?? ""])
        }
        explorePostIds = cachePostsAndGetArrayOfPostIdsFrom(posts: loadedPosts)
    }
    
    func loadSubmissions() async throws {
        submissionIds = cachePostsAndGetArrayOfPostIdsFrom(posts: try await PostAPI.fetchPostsByAuthor(userId: UserService.singleton.getId()))
    }
    
    //Called by FavoriteService after favorites are loaded in
    func loadFavorites(favoritedPostIds: [Int]) async throws {
        favoriteIds = cachePostsAndGetArrayOfPostIdsFrom(posts: try await PostAPI.fetchPostsByIds(ids: favoritedPostIds))
    }
    
    //Called by ConversationService after conversations are loaded in
    func initializeConversationPosts(with posts: [Post]) {
        conversationPostIds = cachePostsAndGetArrayOfPostIdsFrom(posts: posts)
    }
    
    //MARK: - Helpers
    
    func cachePostsAndGetArrayOfPostIdsFrom(posts: [Post]) -> [Int] {
        var postIds = [Int]()
        for post in posts {
            allLoadedPosts[post.id] = post
            postIds.append(post.id)
        }
        return postIds
    }
    
    func getLoadedPostsFor(postIds: [Int]) -> [Post] {
        return postIds.compactMap { postId in allLoadedPosts[postId] }
    }
        
    func updateAllPostsWithDataFrom(updatedPost: Post) {
        allLoadedPosts[updatedPost.id] = updatedPost
        rerenderAnyVisiblePosts()
    }
    
    func rerenderAnyVisiblePosts() {
        //TODO: for each tab bar index, get the top view controller
        //if there is a post displayed somewhere on that view controller, call its "rerender posts" function
    }
    
    //MARK: - Getting
    
    func getExplorePosts() -> [Post] {
        return getLoadedPostsFor(postIds: explorePostIds)
    }
    
    func getSubmissions() -> [Post] {
        return getLoadedPostsFor(postIds: submissionIds)
    }
    
    func getFavorites() -> [Post] {
        return getLoadedPostsFor(postIds: favoriteIds)
    }
    
    func getExploreFilter() -> PostFilter {
        return explorePostFilter
    }
    
    //Returns Post? because even though the convesation around a post exists, the post might have been deleted at any point in time by the user
    func getConversationPost(withPostId postId: Int) -> Post? {
        return allLoadedPosts[postId]
    }
    
    //MARK: - Explore Filter
    
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
    
    //MARK: - Major user actions
    
    func uploadPost(title: String,
                    text: String,
                    locationDescription: String?,
                    latitude: Double?,
                    longitude: Double?,
                    timestamp: Double) async throws {
        let newPost = try await PostAPI.createPost(title: title,
                                                   text: text,
                                                   locationDescription: locationDescription,
                                                   latitude: latitude,
                                                   longitude: longitude,
                                                   timestamp: timestamp,
                                                   author: UserService.singleton.getId())
        allLoadedPosts[newPost.id] = newPost
        
        submissionIds.insert(newPost.id, at: 0)
        explorePostIds.insert(newPost.id, at: 0)
    }
    
    func deletePost(postId: Int) async throws {
        try await PostAPI.deletePost(post_id: postId)
        
        allLoadedPosts.removeValue(forKey: postId)
        
        explorePostIds.removeFirstAppearanceOf(object: postId)
        conversationPostIds.removeAll { $0 == postId }
        submissionIds.removeFirstAppearanceOf(object: postId)
        favoriteIds.removeFirstAppearanceOf(object: postId)
//        mentions.removeAll { $0 == postId }
        
        rerenderAnyVisiblePosts()
    }
        
    //TODO: well, we should also be adding/removing posts to other arrays here, too
    
    //all of the functions below, well, they arent interacting with the database.
    //theyre just adding or removing an existingLoadedPost from a postId array depeneding on user interaction
        
    func addPostToConversationPosts(post: Post) {
        conversationPostIds.append(post.id)
    }
    
    func removePostFromConversationPosts(postId: Int) {
        conversationPostIds.removeFirstAppearanceOf(object: postId)
    }
    
}
