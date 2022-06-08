//
//  PostService.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation
import MapKit

class PostsService: NSObject {
//    private var posts = [Post]()
//    private var filter = PostFilter()
    
    //static let noResultsLeftPost: Post?
        
    static var initialPosts = [Post]()
    static func loadInitialPosts() async throws {
        initialPosts = try await PostAPI.fetchPosts()
    }
    
    //MARK: - Helpers
    
//    func isValidIndex(_ index: Int) -> Bool {
//        if (index < posts.count && index >= 0) {
//            return true
//        } else {
//            return false
//        }
//    }
    
    //MARK: - Setters
    
//    func setFilter(to filter: PostFilter) {
//        self.filter = filter;
//    }
    
    //MARK: - Getters
    
//    func numberOfPosts() -> Int {
//        return posts.count
//    }
//
//    func getPosts() -> [Post] {
//        return posts;
//    }
    
    static func newPosts() async throws -> [Post] {
        return try await PostAPI.fetchPosts()
    }
    
    static func newPostsNearby(latitude: Double, longitude: Double) async throws -> [Post] {
        return try await PostAPI.fetchPostsByLatitudeLongitude(latitude: latitude, longitude: longitude)
    }
    
//    //Returns a card at a given index
//    func getPost(at index: Int) -> Post? {
//        if (isValidIndex(index)) {
//            return posts[index]
//        }
//        else  {
//            print("Not a valid index")
//            return nil;
//        }
//    }
//
//    func insert(post: Post, at index: Int) {
//        self.posts.insert(post, at: index)
//    }

    
//    func deletePost(at index: Int, userID: String) {
//        if (isValidIndex(index)) {
//            posts.remove(at: index) //all elements after are automatically re-indexed to close the gap
//            //TODO: update database
//        }
//    }
//
//    func toggleUpvotePost(at index: Int) {
//        if (isValidIndex(index)) {
//            //if is upvoted, unupvote
//
//            //else if is downvoted, undownvote and upvote
//
//            //else just upvote
//            posts[index].upvotes = posts[index].upvotes + 1
//
//            //TODO: db calls
//        } else { print("Not a valid index") }
//    }
//
//    func toggleDownvotePost(at index: Int) {
//
//    }
//
    
    //user has scrolled far down enough, so fetch 10 more posts
//    func fetchNewPosts(completion: @escaping () -> Void) {
//        //get the end post's value of the variable which the posts are sorted by so that FirestoreManager knows which posts to query
//        //example: if sorting by upvotes, you want the 10 posts with the next highest upvotes after the current end post
//        var endPostOrderByValue: Any
//
//        if (posts.isEmpty) {
//            endPostOrderByValue = INT64_MAX
//        } else {
//            if (orderBy == OrderBy.timestamp) {
//                endPostOrderByValue = posts[posts.endIndex-1].getTimestamp()
//            } else if (orderBy == OrderBy.upvotes) {
//                print(posts)
//                print(posts.endIndex)
//                endPostOrderByValue = (Int64)(posts[posts.endIndex-1].getUpvotes());
//            } else {// (orderBy == OrderBy.trendscore){
//                endPostOrderByValue = (Int64)(posts[posts.endIndex-1].getTrendscore());
//            }
//        }
//
//        FirestoreManager.shared.fetchPosts(orderBy: orderBy, endPostOrderByValue: endPostOrderByValue) { fetchedPosts in
//            if (fetchedPosts.isEmpty) {
//            } else {
//                self.posts = self.posts + fetchedPosts
//                completion()
//            }
//        }
//    }
}
