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
    private var exploreNewPostIds = [Int]()
    private var exploreBestPostIds = [Int]()

    private var conversationPostIds = [Int]()
    private var submissionPostIds = [Int]()
    private var favoritePostIds = [Int]()
    private var mentionPostIds = [Int]()
    
    private var connectedPostIds = Set<Int>()
    
    private var exploreNewPostFilter = FeedPostFilter(postSort: .RECENT)
    private var exploreBestPostFilter = FeedPostFilter(postSort: .TRENDING)
    private var mapPostFilter = MapPostFilter()
    
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
            if let promptsVC = visibleVC as? PromptsViewController {
                promptsVC.navBar.accountBadgeHub.setCount(DeviceService.shared.unreadMentionsCount())
                promptsVC.navBar.accountBadgeHub.bump()
            } else if let conversationsVC = visibleVC as? ConversationsViewController {
                conversationsVC.customNavBar.accountBadgeHub.setCount(DeviceService.shared.unreadMentionsCount())
                conversationsVC.customNavBar.accountBadgeHub.bump()
            }
        }
    }
    
    //MARK: - Load and setup
    
    func loadFeederPosts() async {
        exploreNewPostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: FeederData.posts)
        exploreBestPostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: FeederData.posts)
    }
    
    func loadExploreFeedPostsIfPossible(feed: SortOrder) async throws {
        guard feed != .BEST else { return } //for now, only consider feeds new and best
        var filter = feed == .RECENT ? exploreNewPostFilter : exploreBestPostFilter
        var postIds = feed == .RECENT ? exploreNewPostIds : exploreBestPostIds
        
        guard !filter.isFeedFullyLoaded else { return }
        
        let loadedPosts: [Post]
        if let queryWords = filter.textFilter {
            loadedPosts = try await PostAPI.fetchPostsByWords(words: queryWords, order: filter.postSort, page: filter.pageNumber)
        } else {
            loadedPosts = try await PostAPI.fetchPosts(order: filter.postSort, page: filter.pageNumber)
        }
        guard !loadedPosts.isEmpty else {
            filter.isFeedFullyLoaded = true
            return
        }
        if filter.pageNumber == FeedPostFilter.MIN_PAGE_NUMBER {
            postIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: loadedPosts)
        } else {
            postIds.append(contentsOf: await cachePostsAndGetArrayOfPostIdsFrom(posts: loadedPosts))
        }
        filter.pageNumber += 1
        
        //update filter, since it's a struct
        switch feed {
        case .RECENT:
            exploreNewPostFilter = filter
            exploreNewPostIds = postIds
        case .TRENDING:
            exploreBestPostFilter = filter
            exploreBestPostIds = postIds
        case .BEST:
            break
        }
    }
    
    func isReadyForNewMapSearch() -> Bool {
        let plane = mapPostFilter.currentMapPlaneAndRegion.0
        let region = mapPostFilter.currentMapPlaneAndRegion.1

        guard let mapRegionsForPlane = mapPostFilter.searchedMapRegions[plane] else { return true }
        for searchedRegion in mapRegionsForPlane {
            if searchedRegion.center.distanceInKilometers(from: region.center) < convertLatDeltaToKms(searchedRegion.span.latitudeDelta) / 2 {
                return false
            }
        }
        
        return true
    }
    
    func loadAndOverwriteExploreMapPosts() async throws {        
        let plane = mapPostFilter.currentMapPlaneAndRegion.0
        let region = mapPostFilter.currentMapPlaneAndRegion.1
                
        let loadedPosts: [Post]
        if let queryWords = mapPostFilter.textFilter {
            loadedPosts = try await PostAPI.fetchPostsByWords(words: queryWords)
        } else {
            loadedPosts = try await PostAPI.fetchPostsByLatitudeLongitude(
                latitude: region.center.latitude,
                longitude: region.center.longitude,
                radius: convertLatDeltaToKms(region.span.latitudeDelta) / 2,
                order: mapPostFilter.postSort) //adding the /2 bc we were using too large of a region to find the best posts
        }
        
        if mapPostFilter.searchedMapRegions[plane] != nil {
            mapPostFilter.searchedMapRegions[plane]!.append(region)
        } else {
            mapPostFilter.searchedMapRegions[plane] = [region]
        }
                        
        allExploreMapPostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: loadedPosts)
        newExploreMapPostIds =  allExploreMapPostIds
    }
    
    func loadAndAppendExploreMapPosts() async throws {
        guard isReadyForNewMapSearch() else { return }
        
        guard mapPostFilter.textFilter == nil else { return }
        
        let plane = mapPostFilter.currentMapPlaneAndRegion.0
        let region = mapPostFilter.currentMapPlaneAndRegion.1
        
        let loadedPosts = try await PostAPI.fetchPostsByLatitudeLongitude(
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            radius: convertLatDeltaToKms(region.span.latitudeDelta),
            order: mapPostFilter.postSort) //adding the /2 bc we were using too large of a region to find the best posts
                
        if mapPostFilter.searchedMapRegions[plane] != nil {
            mapPostFilter.searchedMapRegions[plane]!.append(region)
        } else {
            mapPostFilter.searchedMapRegions[plane] = [region]
        }
                
        let uniqueNewPosts = loadedPosts.filter { !allExploreMapPostIds.contains($0.id) }
        allExploreMapPostIds.append(contentsOf: uniqueNewPosts.map { $0.id })
        newExploreMapPostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: uniqueNewPosts)
    }
    
    func loadSubmissions() async throws {
        let submissions = try await PostAPI.fetchSubmittedPosts()
        await submissionPostIds = cachePostsAndGetArrayOfPostIdsFrom(posts: submissions)
    }
    
    func loadMentions() async throws {
        let posts = try await PostAPI.fetchTaggedPosts()
        await mentionPostIds = cachePostsAndGetArrayOfPostIdsFrom(posts: posts)
    }
    
    func loadConnections() async throws {
        let posts = try await PostAPI.fetchMatchedPosts()
        connectedPostIds = Set(await cachePostsAndGetArrayOfPostIdsFrom(posts: posts))
    }
    
    //Called by FavoriteService after favorites are loaded in
    func loadFavorites(favoritedPostIds: [Int]) async throws {
        guard !favoritedPostIds.isEmpty else { return }
        
//        TODO: factor out favoritedPostids
        let favorites = try await PostAPI.fetchFavoritedPosts()
        favoritePostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: favorites)
//        favoritePostIds = await cachePostsAndGetArrayOfPostIdsFrom(posts: try await PostAPI.fetchPostsByIds(ids: favoritedPostIds))
        
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
    
    func getExploreNewPosts() -> [Post] {
        return getLoadedPostsFor(postIds: exploreNewPostIds)
    }
    
    func getExploreBestPosts() -> [Post] {
        return getLoadedPostsFor(postIds: exploreBestPostIds)
    }
    
    func getAllExploreMapPosts() -> [Post] {
        return getLoadedPostsFor(postIds: allExploreMapPostIds)
    }
    
    //so that we don't have to iterate through all the map posts from the cache when sorting cluster annotations
    func getExploreMapPostsSortedIds() -> [Int] {
        return allExploreMapPostIds
    }
    
    func getExploreBestPostsSortedIds() -> [Int] {
        return exploreBestPostIds
    }
    
    func getExploreNewPostsSortedIds() -> [Int] {
        return exploreNewPostIds
    }
    
    func getNewExploreMapPosts() -> [Post] {
        return getLoadedPostsFor(postIds: newExploreMapPostIds)
    }
    
    func getSubmissions() -> [Post] {
        return getLoadedPostsFor(postIds: submissionPostIds)
    }
    
    func isConnectedPost(postId: Int) -> Bool {
        return connectedPostIds.contains(postId)
    }
    
    func getFavorites() -> [Post] {
        return getLoadedPostsFor(postIds: favoritePostIds)
    }
    
    func getMentions() -> [Post] {
        return getLoadedPostsFor(postIds: mentionPostIds)
    }
    
    func getMapPostFilter() -> MapPostFilter {
        return mapPostFilter
    }
        
    func getPost(withPostId postId: Int) -> Post? {
        return cachedPosts[postId]
    }
    
    //MARK: - Explore Filter
    
    func resetEverything() {
        resetFilters()
        
        cachedPosts = [:]
        allExploreMapPostIds = [Int]()
        newExploreMapPostIds = [Int]()
        exploreNewPostIds = [Int]()
        exploreBestPostIds = [Int]()
        conversationPostIds = [Int]()
        submissionPostIds = [Int]()
        favoritePostIds = [Int]()
        mentionPostIds = [Int]()
    }
    
    func resetFilters() {
        mapPostFilter = .init()
        exploreNewPostFilter = .init(postSort: .RECENT)
        exploreBestPostFilter = .init(postSort: .TRENDING)
    }
    
    func resetNewPostFilter() {
        exploreNewPostFilter = .init(postSort: .RECENT)
    }
    
    func updateFiltersWithWords(words: [String]?) {
        exploreNewPostFilter.textFilter = words
        exploreBestPostFilter.textFilter = words
        mapPostFilter.textFilter = words
    }
    
    //Could be used by bestFilter later on
//    func updateFilter(newPostSort: SortOrder) {
//        exploreBestPostIds.postSort = newPostSort //page and wasFeedFullyReloaded are automatically reset
//    }
    
    func updateFilter(newPlaneAndRegion: (Int,MKCoordinateRegion)) {
        mapPostFilter.currentMapPlaneAndRegion = newPlaneAndRegion
    }
    
    //MARK: - Major user actions
    
    func uploadPost(title: String,
                    text: String,
                    locationDescription: String?,
                    latitude: Double?,
                    longitude: Double?,
                    timestamp: Double,
                    collectibleType: Int?) async throws {
        let newPost = try await PostAPI.createPost(title: title,
                                                   text: text,
                                                   locationDescription: locationDescription,
                                                   latitude: latitude,
                                                   longitude: longitude,
                                                   timestamp: timestamp,
                                                   author: UserService.singleton.getId(),
                                                   collectibleType: collectibleType)
        cachedPosts[newPost.id] = newPost
        
        submissionPostIds.insert(newPost.id, at: 0)
        exploreNewPostIds.insert(newPost.id, at: 0)
        allExploreMapPostIds.insert(newPost.id, at: 0)
    }
    
    func deletePost(postId: Int) async throws {
        try await PostAPI.deletePost(post_id: postId)
        cachedPosts.removeValue(forKey: postId)
        
        exploreNewPostIds.removeFirstAppearanceOf(object: postId)
        exploreBestPostIds.removeFirstAppearanceOf(object: postId)
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
