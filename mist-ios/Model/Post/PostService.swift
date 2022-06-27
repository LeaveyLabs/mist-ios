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
    
    //TODo: add postFilter to PostService object
    private var posts = [Post]()
    private var postFilter = PostFilter()
    
    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    func loadPosts() async throws {
        print(postFilter.searchBy)
        switch postFilter.searchBy {
        case .all:
            posts = try await PostAPI.fetchPosts()
        case .location:
            posts = try await PostAPI.fetchPostsByLatitudeLongitude(latitude: postFilter.region.center.latitude, longitude: postFilter.region.center.longitude, radius: convertLatDeltaToKms(postFilter.region.span.latitudeDelta))
        case .text:
            posts = try await PostAPI.fetchPostsByWords(words: [postFilter.text ?? ""])
        }
    }
    
    func getPosts() -> [Post] {
        return posts
    }
    
    func getFilter() -> PostFilter {
        return postFilter
    }
    
    //MARK: - Update filter
    
    func resetFilter() {
        postFilter = .init()
    }
    
    func updateFilter(newPostFilter: PostFilter) {
        postFilter = newPostFilter
    }
    
    func updateFilter(newText: String?) {
        postFilter.text = newText
    }
    
    func updateFilter(newTimeframe: Float) {
        postFilter.postTimeframe = newTimeframe
    }
    
    func updateFilter(newPostType: PostType) {
        postFilter.postType = newPostType
    }
    
    func updateFilter(newSearchBy: SearchBy) {
        postFilter.searchBy = newSearchBy
    }
    
    func updateFilter(newRegion: MKCoordinateRegion) {
        postFilter.region = newRegion
    }
    
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
    }
    
    func deletePost(postId: Int) async throws {
        try await PostAPI.deletePost(post_id: postId)
    }
    
}
