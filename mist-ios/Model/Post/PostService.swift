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
    
    private var allExploreMapPostIds = [Int]()
    private var newExploreMapPostIds = [Int]()
    private var exploreFeedPostIds = [Int]()
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
        startBackgroundRefreeshTask()
    }
    
    func startBackgroundRefreeshTask() {
        Task {
            while true {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 10)
                try await checkForNewMentions()
            }
        }
    }
    
    func checkForNewMentions() async throws {
        let prevMentionCount = DeviceService.shared.unreadMentionsCount()
        try await PostService.singleton.loadMentions()
        try await CommentService.singleton.fetchTaggedTags()
        guard DeviceService.shared.unreadMentionsCount() > prevMentionCount else { return }
        
        DispatchQueue.main.async {
            guard let tabVC = UIApplication.shared.windows.first?.rootViewController as? SpecialTabBarController else { return }
            tabVC.refreshBadgeCount()
            let visibleVC = SceneDelegate.visibleViewController
            if let mistboxVC = visibleVC as? MistboxViewController {
                mistboxVC.navBar.accountBadgeHub.setCount(DeviceService.shared.unreadMentionsCount())
                mistboxVC.navBar.accountBadgeHub.bump()
            } else if let conversationsVC = visibleVC as? ConversationsViewController {
                conversationsVC.customNavBar.accountBadgeHub.setCount(DeviceService.shared.unreadMentionsCount())
                conversationsVC.customNavBar.accountBadgeHub.bump()
            }
        }
    }
    
    //MARK: - Load and setup
    
    func loadFeederPosts() async {
        exploreFeedPostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: FeederData.posts)
    }
    
    func loadExploreFeedPostsIfPossible() async throws {
        guard !explorePostFilter.isFeedFullyLoaded else { return }
        let loadedPosts: [Post] = try await PostAPI.fetchPosts(order: explorePostFilter.postSort, page: explorePostFilter.pageNumber)
        guard !loadedPosts.isEmpty else {
            explorePostFilter.isFeedFullyLoaded = true
            return
        }
        if explorePostFilter.pageNumber == PostFilter.MIN_PAGE_NUMBER {
            exploreFeedPostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: loadedPosts)
        } else {
            exploreFeedPostIds.append(contentsOf: await cachePostsAndGetArrayOfPostIdsFrom(posts: loadedPosts))
        }
        explorePostFilter.pageNumber += 1
    }
    
    func isReadyForNewMapSearch() -> Bool {
        let plane = explorePostFilter.currentMapPlaneAndRegion.0
        let region = explorePostFilter.currentMapPlaneAndRegion.1

        guard let mapRegionsForPlane = explorePostFilter.searchedMapRegions[plane] else { return true }
        for searchedRegion in mapRegionsForPlane {
            if searchedRegion.center.distanceInKilometers(from: region.center) < convertLatDeltaToKms(searchedRegion.span.latitudeDelta) / 2 {
                return false
            }
        }
        
        return true
    }
    
    //TODO: we might want to reset postfilter here
    func loadAndOverwriteExploreMapPosts() async throws {
        guard isReadyForNewMapSearch() else { return }
        
        let plane = explorePostFilter.currentMapPlaneAndRegion.0
        let region = explorePostFilter.currentMapPlaneAndRegion.1
        
        let loadedPosts = try await PostAPI.fetchPostsByLatitudeLongitude(latitude: region.center.latitude, longitude: region.center.longitude, radius: convertLatDeltaToKms(region.span.latitudeDelta))
        
        if explorePostFilter.searchedMapRegions[plane] != nil {
            explorePostFilter.searchedMapRegions[plane]!.append(region)
        } else {
            explorePostFilter.searchedMapRegions[plane] = [region]
        }
        
        allExploreMapPostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: loadedPosts)
        newExploreMapPostIds =  allExploreMapPostIds
    }
    
    func loadAndAppendExploreMapPosts() async throws {
        guard isReadyForNewMapSearch() else { return }
        
        let plane = explorePostFilter.currentMapPlaneAndRegion.0
        let region = explorePostFilter.currentMapPlaneAndRegion.1
        
        let loadedPosts = try await PostAPI.fetchPostsByLatitudeLongitude(latitude: region.center.latitude, longitude: region.center.longitude, radius: convertLatDeltaToKms(region.span.latitudeDelta))
        
        if explorePostFilter.searchedMapRegions[plane] != nil {
            explorePostFilter.searchedMapRegions[plane]!.append(region)
        } else {
            explorePostFilter.searchedMapRegions[plane] = [region]
        }
                
        allExploreMapPostIds.append(contentsOf: newExploreMapPostIds)
        newExploreMapPostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: loadedPosts).filter {
            !allExploreMapPostIds.contains($0)
        }
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
        guard !favoritedPostIds.isEmpty else { return }
        favoritePostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: try await PostAPI.fetchPostsByIds(ids: favoritedPostIds))
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
    }
    
    func updateCachedPostWith(postId: Int, updatedEmojiDict: EmojiCountDict) {
        cachedPosts[postId]?.emoji_dict = updatedEmojiDict
    }
    
    //MARK: - Getting
    
    func getExploreFeedPosts() -> [Post] {
        return getLoadedPostsFor(postIds: exploreFeedPostIds)
    }
    
    func getAllExploreMapPosts() -> [Post] {
        return getLoadedPostsFor(postIds: allExploreMapPostIds)
    }
    
    func getNewExploreMapPosts() -> [Post] {
        return getLoadedPostsFor(postIds: newExploreMapPostIds)
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
        
    func getPost(withPostId postId: Int) -> Post? {
        return cachedPosts[postId]
    }
    
    //MARK: - Explore Filter
    
    func resetFilter() {
        explorePostFilter = PostFilter()
    }
    
    func updateFilter(newPostSort: SortOrder) {
        explorePostFilter.postSort = newPostSort //page and wasFeedFullyReloaded are automatically reset
    }
    
    func updateFilter(newPostType: PostType) {
        explorePostFilter.postType = newPostType
    }
    
    func updateFilter(newPlaneAndRegion: (Int,MKCoordinateRegion)) {
        explorePostFilter.currentMapPlaneAndRegion = newPlaneAndRegion
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
        exploreFeedPostIds.insert(newPost.id, at: 0)
        allExploreMapPostIds.insert(newPost.id, at: 0)
    }
    
    func deletePost(postId: Int) async throws {
        try await PostAPI.deletePost(post_id: postId)
        cachedPosts.removeValue(forKey: postId)
        
        exploreFeedPostIds.removeFirstAppearanceOf(object: postId)
        conversationPostIds.removeFirstAppearanceOf(object: postId)
        submissionPostIds.removeFirstAppearanceOf(object: postId)
        favoritePostIds.removeFirstAppearanceOf(object: postId)
        mentionPostIds.removeFirstAppearanceOf(object: postId)
    }
    
    func setConversationPostIds(postIds: [Int]) {
        conversationPostIds = postIds
    }
    
    func setFavoritePostIds(postIds: [Int]) {
        favoritePostIds = postIds
    }
    
}
