// Acquires posts from the datbase

import Foundation

enum PostError: Error {
    case badAPIEndPoint
    case badId
}

class PostAPI {
    // Fetches all posts from database
    static func fetchPosts() async throws -> [Post] {
        let url = "https://mist-backend.herokuapp.com/api/posts/"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database (searching for the below text)
    static func fetchPosts(text:String) async throws -> [Post] {
        let url = "https://mist-backend.herokuapp.com/api/posts?text=\(text)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database (searching with latitude + longitude)
    static func fetchPosts(latitude:Double, longitude:Double) async throws -> [Post] {
        let url = "https://mist-backend.herokuapp.com/api/posts?latitude=\(latitude)?longitude=\(longitude)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database (searching with location description)
    // TODO: Rewrite the function earlier signatures so that we can do this

    // Posts post in the database
    static func createPost(post:Post) async throws -> Post {
        let url = "https://mist-backend.herokuapp.com/api/posts/"
        let json = try JSONEncoder().encode(post)
        let data = try await BasicAPI.post(url:url, jsonData:json)
        return try JSONDecoder().decode(Post.self, from: data)
    }
    
    // Deletes post from the database
    static func deletePost(id:String) async throws -> Post {
        let url = "https://mist-backend.herokuapp.com/api/posts/\(id)/"
        let data = try await BasicAPI.delete(url:url,jsonData:Data())
        return try JSONDecoder().decode(Post.self, from: data)
    }
}
