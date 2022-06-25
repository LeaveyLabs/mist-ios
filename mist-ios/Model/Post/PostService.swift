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
    
    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    func loadPosts() async throws {
        posts = try await PostAPI.fetchPosts()
    }
    
    func getPosts() -> [Post] {
        return posts
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
