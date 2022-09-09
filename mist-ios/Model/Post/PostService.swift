//
//  PostService.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation
import MapKit

protocol DisplayingPostDelegate {
    func rerenderPostUIAfterPostServiceUpdate()
}

class PostService: NSObject {
    
    static var singleton = PostService()
    
    private var cachedPosts = [Int: Post]() //[postId: post]
    
    private var explorePostIds = [Int]()
    private var conversationPostIds = [Int]()
    private var submissionPostIds = [Int]()
    private var favoritePostIds = [Int]()
    private var mentionPostIds = [Int]()
    
    private var explorePostFilter = PostFilter()
    
    //NOTE: i considered making PostService an actor, but that requires us to await any access to the cachedPosts throughout the app
    //This is probably the way to go down the road (if someone clicks on a post, the screen should immediately open up, and there could be a loading screen for half a second or so until the cache is able to be accessed
    //For now, we'll just use this single cacheQueue so that after loading in posts, cachedPosts is only written to one at a time
    private let cacheQueue = DispatchQueue(label: "cache", qos: .userInitiated)

    
    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    //MARK: - Load and setup
    
    func loadFeederPosts() async {
        explorePostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: FeederData.posts)
    }
        
    func loadExplorePosts() async throws {
        let loadedPosts: [Post]
        switch explorePostFilter.searchBy {
        case .all:
            loadedPosts = try await PostAPI.fetchPosts()
        case .location:
            loadedPosts = try await PostAPI.fetchPostsByLatitudeLongitude(latitude: explorePostFilter.region.center.latitude, longitude: explorePostFilter.region.center.longitude, radius: convertLatDeltaToKms(explorePostFilter.region.span.latitudeDelta))
        case .text:
            let searchWords = explorePostFilter.text?.components(separatedBy: .whitespaces)
            loadedPosts = try await PostAPI.fetchPostsByWords(words: searchWords ?? [""])
        }
        explorePostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: loadedPosts)
    }
    
    func loadSubmissions() async throws {
        let submissions = try await PostAPI.fetchPostsByAuthor(userId: UserService.singleton.getId())
        await submissionPostIds = cachePostsAndGetArrayOfPostIdsFrom(posts: submissions)
    }
    
    func loadMentions() async throws {
        let posts = try await PostAPI.fetchTaggedPosts()
        await mentionPostIds = cachePostsAndGetArrayOfPostIdsFrom(posts: posts)
    }
    
    //Called by FavoriteService after favorites are loaded in
    func loadFavorites(favoritedPostIds: [Int]) async throws {
        //TODO: we should remove this bottom check if kevin updates the backend accordingly
        if !favoritedPostIds.isEmpty {
            favoritePostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: try await PostAPI.fetchPostsByIds(ids: favoritedPostIds))
        }
    }
    
    //Called by ConversationService after conversations are loaded in
    func initializeConversationPosts(with posts: [Post]) async {
        conversationPostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: posts)
    }
    
    //MARK: - Helpers
    
    func cachePostsAndGetArrayOfPostIdsFrom(posts: [Post]) async -> [Int] {
        return await withCheckedContinuation({ continuation in
            cacheQueue.async { [self] in
                var postIds = [Int]()
                for post in posts {
                    cachedPosts[post.id] = post
                    postIds.append(post.id)
                }
                continuation.resume(returning: postIds)
            }
        })
    }
    
    func getLoadedPostsFor(postIds: [Int]) -> [Post] {
        return postIds.compactMap { postId in cachedPosts[postId] }
    }
        
    func updateCachedPostWithDataFrom(updatedPost: Post) {
        cachedPosts[updatedPost.id] = updatedPost
        rerenderAnyVisiblePosts()
    }
    
    func updateCachedPostWith(postId: Int, updatedEmojiDict: EmojiCountDict) {
        print("CACHED POST BEFORE:", cachedPosts[postId]?.emoji_dict)
        cachedPosts[postId]?.emoji_dict = updatedEmojiDict
        print("CACHED POST BEFORE:", cachedPosts[postId]?.emoji_dict)
        rerenderAnyVisiblePosts()
    }
    
    //the other problem: we need to make sure PostViewController, etc actually depend on PostService for posts. right now, Explore does depend on PostService, but PostViewController does not
    //hmmm - instead of passing Post from explore to PostVC, we'd want to pass the postId, yea? than we can just call PostService.getPost(forId: ) throughout PostVC
    func rerenderAnyVisiblePosts() {
//        DispatchQueue.main.async {
//            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//            let delegate = windowScene.delegate as? SceneDelegate, let window = delegate.window else { return }
//            guard let tabVC = window.rootViewController as? UITabBarController else { return }
//            let firstNavVC = tabVC.viewControllers![0] as! UINavigationController
//            let secondNavVC = tabVC.viewControllers![2] as! UINavigationController
//            guard let visibleFirstVC = firstNavVC.visibleViewController! as? DisplayingPostDelegate else { return }
//            guard let visibleSecondVC = secondNavVC.visibleViewController! as? DisplayingPostDelegate else { return }
//            visibleFirstVC.rerenderPostUIAfterPostServiceUpdate()
//            visibleSecondVC.rerenderPostUIAfterPostServiceUpdate()
//        }
    }
    
    //MARK: - Getting
    
    func getExplorePostCount() -> Int {
        return getLoadedPostsFor(postIds: explorePostIds).count
    }
    
    func getExplorePosts() -> [Post] {
        return getLoadedPostsFor(postIds: explorePostIds)
    }
    
    func getSubmissions() -> [Post] {
        return getLoadedPostsFor(postIds: submissionPostIds)
    }
    
    func getFavorites() -> [Post] {
        return getLoadedPostsFor(postIds: favoritePostIds)
    }
    
    func getMentions() -> [Post] {
        return getLoadedPostsFor(postIds: mentionPostIds)
    }
    
    func getExploreFilter() -> PostFilter {
        return explorePostFilter
    }
    
    //TODO: i think the below function would be used by PostVC too. so why not just call it "getPost"? doesnt have to be specific to conversation posts. and of course it'll return Post?
    
    //Returns Post? because even though the convesation around a post exists, the post might have been deleted at any point in time by the user
    func getPost(withPostId postId: Int) -> Post? {
        return cachedPosts[postId]
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
        cachedPosts[newPost.id] = newPost
        
        submissionPostIds.insert(newPost.id, at: 0)
        explorePostIds.insert(newPost.id, at: 0)
    }
    
    func deletePost(postId: Int) async throws {
        try await PostAPI.deletePost(post_id: postId)
        cachedPosts.removeValue(forKey: postId)
        
        explorePostIds.removeFirstAppearanceOf(object: postId)
        conversationPostIds.removeAll { $0 == postId }
        submissionPostIds.removeFirstAppearanceOf(object: postId)
        favoritePostIds.removeFirstAppearanceOf(object: postId)
//        mentions.removeAll { $0 == postId }
        
        rerenderAnyVisiblePosts()
    }
    
    func setConversationPostIds(postIds: [Int]) {
        conversationPostIds = postIds
    }
    
    func setFavoritePostIds(postIds: [Int]) {
        favoritePostIds = postIds
    }
    
}
