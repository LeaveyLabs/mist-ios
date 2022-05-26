// Acquires posts from the datbase

import Foundation

enum PostError: Error {
    case badAPIEndPoint
    case badId
}

class PostAPI {
    
    //TODO: implement this properly
    // Fetches a post for a particular ID
    static func fetchPostsByPostID(postId:Int) async throws -> [Post] {
        let url = "https://mist-backend.herokuapp.com/api/posts/\(postId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: "GET")
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database
    static func fetchPosts() async throws -> [Post] {
        let url = "https://mist-backend.herokuapp.com/api/posts/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: "GET")
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database (searching for the below text)
    static func fetchPostsByText(text:String) async throws -> [Post] {
        let url = "https://mist-backend.herokuapp.com/api/posts?text=\(text)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: "GET")
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database (searching with latitude + longitude)
    static func fetchPostsByLatitudeLongitude(latitude:Double, longitude:Double) async throws -> [Post] {
        let url = "https://mist-backend.herokuapp.com/api/posts?latitude=\(latitude)?longitude=\(longitude)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: "GET")
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database (searching with location description)
    // TODO: Rewrite the function earlier signatures so that we can do this

    // Posts post in the database
    static func createPost(title: String,
                           text: String,
                           locationDescription: String?,
                           latitude: Double?,
                           longitude: Double?) async throws -> Post {
        let url = "https://mist-backend.herokuapp.com/api/posts/"
        let post = Post(title: title,
                        text: text,
                        location_description: locationDescription,
                        latitude: latitude,
                        longitude: longitude,
                        timestamp: currentTimeMillis(),
                        author: UserService.singleton.getId()!)
        let json = try JSONEncoder().encode(post)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: "POST")
        return try JSONDecoder().decode(Post.self, from: data)
    }
    
    // Deletes post from the database
    static func deletePost(id:Int) async throws {
        let url = "https://mist-backend.herokuapp.com/api/posts/\(id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: "DELETE")
    }
}
