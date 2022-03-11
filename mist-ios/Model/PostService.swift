//
//  PostService.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

class PostService: NSObject {
    private var posts = [Post]();
    private var sortBy: SortBy = SortBy.upvotes;
    
    //static let noResultsLeftPost: Post?
    
    static var homePosts = PostService(); //why use singleton model? just put it in homeVC?
    static var myPosts = PostService();
    
    func isValidIndex(_ index: Int) -> Bool {
        if (index < posts.count && index >= 0) {
            return true
        } else {
            return false
        }
    }
    
    func numberOfPosts() -> Int {
        return posts.count
    }
    
    func getPosts() -> [Post] {
        return posts;
    }
    
    func newPosts() -> Void {
        Task {
            do {
                let request_posts = try await fetchPosts();
                self.posts = request_posts;
            } catch {
                
            }
        }
    }
    
    func changeSortBy(to newSortBy: SortBy) {
        sortBy = newSortBy;
        
        //TODO: reload all data and refresh the viewController
    }
    
    //Returns a card at a given index
    func getPost(at index: Int) -> Post? {
        if (isValidIndex(index)) {
            return posts[index]
        }
        else  {
            print("Not a valid index")
            return nil;
        }
    }
    
    private func insert(post: Post, at index: Int) {
        self.posts.insert(post, at: index)
    }
    
    static func uploadPost(title: String, location: String, message: String, completion: (Post?) -> Void) {
        let uuid = NSUUID().uuidString;
        let newPost = Post(id: String(uuid.prefix(10)),
                           title: title,
                           text: message,
                           location: location,
                           timestamp: currentTimeMillis(),
                           votes: [],
                           author: "kevinsun");
        print(newPost.timestamp)
        //TODO: database call plus callback
        // Database call
        guard let serviceUrl = URL(string: "https://mist-backend.herokuapp.com/api/posts/") else { return; }
        var request = URLRequest(url: serviceUrl);
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(newPost);
        request.httpMethod = "POST";
        request.httpBody = jsonData;
        request.setValue("application/json", forHTTPHeaderField: "Content-Type");
        URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, error: Error?) in
            let outputStr = String(data: data!, encoding: String.Encoding.utf8);
            print(outputStr);
        }.resume();
        // Modify user
        if (true) {
            //change the calling objects below from PostService to Feed?
            PostService.homePosts.insert(post: newPost, at: 0)
            PostService.myPosts.insert(post: newPost, at: 0)
            //UserService.myAccount.addPost(post: newPost)
            completion(newPost);
        } else {
            completion(nil);
        }
    }
    
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
    // TO DO: delete this ... (refactor exists in the APIs folder)
    private func fetchPosts() async throws -> [Post] {
        guard let url = URL(string: "https://mist-backend.herokuapp.com/api/posts/") else {
            return [];
        }
        let (data, _) = try await URLSession.shared.data(from: url);
        let result = try JSONDecoder().decode([Post].self, from: data);
        return result
    }
    
    // Creates post in the database
    private static func createPost(post:Post) async throws -> Bool {
        guard let serviceUrl = URL(string: "https://mist-backend.herokuapp.com/api/posts/") else {
            return false;
        }
        var request = URLRequest(url: serviceUrl);
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(post)
        request.httpMethod = "POST";
        request.httpBody = jsonData;
        request.setValue("application/json", forHTTPHeaderField: "Content-Type");
        let (data, _) = try await URLSession.shared.data(for: request);
        return true;
    }
    
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
