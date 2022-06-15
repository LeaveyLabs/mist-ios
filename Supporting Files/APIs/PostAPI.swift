// Acquires posts from the datbase

import Foundation

class PostAPI {
    static let PATH_TO_POST_MODEL = "api/posts/"
    static let PATH_TO_FEATURED_POSTS = "api/featured-posts/"
    static let PATH_TO_MATCHED_POSTS = "api/matched-posts/"
    static let PATH_TO_FRIEND_POSTS = "api/friend-posts/"
    static let PATH_TO_FAVORITED_POSTS = "api/favorited-posts/"
    static let PATH_TO_SUBMITTED_POSTS = "api/submitted-posts/"
    static let IDS_PARAM = "ids"
    static let TEXT_PARAM = "text"
    static let LATITUDE_PARAM = "latitude"
    static let LONGITUDE_PARAM = "longitude"
    static let LOC_DESCRIPTION_PARAM = "location_description"
    static let AUTHOR_PARAM = "author"
    
    //TODO: implement this properly
    // Fetches all posts from database
    static func fetchPosts() async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_POST_MODEL)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchPostsByIds(ids:[Int]) async throws -> [Post] {
        var url = "\(BASE_URL)\(PATH_TO_POST_MODEL)?"
        for id in ids {
            url += "\(IDS_PARAM)=\(id)&"
        }
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchMatchedPosts() async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_MATCHED_POSTS)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchFeaturedPosts() async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_FEATURED_POSTS)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchFriendPosts() async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_FRIEND_POSTS)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchFavoritedPosts() async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_FAVORITED_POSTS)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchSubmittedPosts() async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_SUBMITTED_POSTS)"
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
    
    
    static func fetchPostsByLocationDescription(locationDescription:String) async throws -> [Post] {
        let url = "\(BASE_URL)\(PATH_TO_POST_MODEL)?\(LOC_DESCRIPTION_PARAM)=\(locationDescription)"
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
                           timestamp: Double,
                           author: Int) async throws -> Post {
        let url = "\(BASE_URL)\(PATH_TO_POST_MODEL)"
        let post = Post(title: title,
                        text: text,
                        location_description: locationDescription,
                        latitude: latitude,
                        longitude: longitude,
                        timestamp: timestamp,
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
