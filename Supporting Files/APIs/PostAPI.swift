// Acquires posts from the datbase

import Foundation

class PostAPI {
    static let PATH_TO_POST_MODEL = "api/posts/"
    static let TEXT_PARAM = "text"
    static let LATITUDE_PARAM = "latitude"
    static let LONGITUDE_PARAM = "longitude"
    static let AUTHOR_PARAM = "author"
    
    //TODO: implement this properly
    // Fetches all posts from database
    static func fetchPosts() async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_POST_MODEL)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches a post for a particular ID
    static func fetchPostsByPostID(postId:Int) async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_POST_MODEL)\(postId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database (searching for the below text)
    static func fetchPostsByText(text:String) async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_POST_MODEL)?\(TEXT_PARAM)=\(text)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database (searching with latitude + longitude)
    static func fetchPostsByLatitudeLongitude(latitude:Double, longitude:Double) async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_POST_MODEL)?\(LATITUDE_PARAM)=\(latitude)&\(LONGITUDE_PARAM)=\(longitude)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches posts by a particular author
    static func fetchPostsByAuthor(userId:Int) async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_POST_MODEL)?\(AUTHOR_PARAM)=\(userId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database (searching with location description)
    // TODO: Rewrite the function earlier signatures so that we can do this

    // Posts post in the database
    static func createPost(title: String,
                           text: String,
                           locationDescription: String?,
                           latitude: Double?,
                           longitude: Double?,
                           author: Int) async throws -> Post {
        let url = "\(BASE_URL)\(PATH_TO_POST_MODEL)"
        let post = Post(title: title,
                        text: text,
                        location_description: locationDescription,
                        latitude: latitude,
                        longitude: longitude,
                        timestamp: currentTimeMillis(),
                        author: author)
        let json = try JSONEncoder().encode(post)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(Post.self, from: data)
    }
    
    // Deletes post from the database
    static func deletePost(id:Int) async throws {
        let url = "\(BASE_URL)\(PATH_TO_POST_MODEL)\(id)/"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
}
