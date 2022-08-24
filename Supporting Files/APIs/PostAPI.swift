// Acquires posts from the datbase

import Foundation

struct PostError: Codable {
    let title: [String]?
    let body: [String]?
    let location_description: [String]?
    let latitude: [String]?
    let longitude: [String]?
    let timestamp: [String]?
    let author: [String]?
    
    let non_field_errors: [String]?
    let detail: [String]?
}

class PostAPI {
    static let PATH_TO_POST_MODEL = "api/posts/"
    static let PATH_TO_FEATURED_POSTS = "api/featured-posts/"
    static let PATH_TO_MATCHED_POSTS = "api/matched-posts/"
    static let PATH_TO_FRIEND_POSTS = "api/friend-posts/"
    static let PATH_TO_FAVORITED_POSTS = "api/favorited-posts/"
    static let PATH_TO_SUBMITTED_POSTS = "api/submitted-posts/"
    static let PATH_TO_KEYWORD_POSTS = "api/keyword-posts/"
    static let PATH_TO_TAGGED_POSTS = "api/tagged-posts/"
    static let IDS_PARAM = "ids"
    static let WORDS_PARAM = "words"
    static let LATITUDE_PARAM = "latitude"
    static let LONGITUDE_PARAM = "longitude"
    static let RADIUS_PARAM = "radius"
    static let LOC_DESCRIPTION_PARAM = "location_description"
    static let AUTHOR_PARAM = "author"
    
    static let POST_RECOVERY_MESSAGE = "Please try again"
    
    static func filterPostErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(PostError.self, from: data)
            
            if let titleErrors = error.title,
               let titleError = titleErrors.first {
                throw APIError.ClientError(titleError, POST_RECOVERY_MESSAGE)
            }
            if let bodyErrors = error.body,
               let bodyError = bodyErrors.first {
                throw APIError.ClientError(bodyError, POST_RECOVERY_MESSAGE)
            }
            if let locErrors = error.location_description,
               let locError = locErrors.first {
                throw APIError.ClientError(locError, POST_RECOVERY_MESSAGE)
            }
            if let latitudeErrors = error.latitude,
               let latitudeError = latitudeErrors.first {
                throw APIError.ClientError(latitudeError, POST_RECOVERY_MESSAGE)
            }
            if let longitudeErrors = error.longitude,
               let longitudeError = longitudeErrors.first {
                throw APIError.ClientError(longitudeError, POST_RECOVERY_MESSAGE)
            }
            if let timestampErrors = error.timestamp,
               let timestampError = timestampErrors.first {
                throw APIError.ClientError(timestampError, POST_RECOVERY_MESSAGE)
            }
            if let authorErrors = error.author,
               let authorError = authorErrors.first {
                throw APIError.ClientError(authorError, POST_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    // Fetches all posts from database
    static func fetchPosts() async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_POST_MODEL)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchPostsByIds(ids:[Int]) async throws -> [Post] {
        var url = "\(Env.BASE_URL)\(PATH_TO_POST_MODEL)?"
        if ids.isEmpty {
            return []
        }
        for id in ids {
            url += "\(IDS_PARAM)=\(id)&"
        }
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchMatchedPosts() async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_MATCHED_POSTS)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchFeaturedPosts() async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FEATURED_POSTS)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchFriendPosts() async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FRIEND_POSTS)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchFavoritedPosts() async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FAVORITED_POSTS)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchSubmittedPosts() async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_SUBMITTED_POSTS)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchKeywordPosts() async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_KEYWORD_POSTS)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchTaggedPosts() async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_TAGGED_POSTS)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches a post for a particular ID
    static func fetchPostByPostID(postId:Int) async throws -> Post {
        let url = "\(Env.BASE_URL)\(PATH_TO_POST_MODEL)\(postId)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode(Post.self, from: data)
    }
    
    // Fetches all posts from database (searching for the below text)
    static func fetchPostsByWords(words:[String]) async throws -> [Post] {
        var url = "\(Env.BASE_URL)\(PATH_TO_POST_MODEL)?"
        for word in words {
            url += "\(WORDS_PARAM)=\(word)&"
        }
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database (searching with latitude + longitude)
    static func fetchPostsByLatitudeLongitude(latitude:Double, longitude:Double) async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_POST_MODEL)?\(LATITUDE_PARAM)=\(latitude)&\(LONGITUDE_PARAM)=\(longitude)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches all posts from database (searching with latitude + longitude + radius)
    static func fetchPostsByLatitudeLongitude(latitude:Double, longitude:Double, radius:Double) async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_POST_MODEL)?\(LATITUDE_PARAM)=\(latitude)&\(LONGITUDE_PARAM)=\(longitude)&\(RADIUS_PARAM)=\(radius)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    static func fetchPostsByLocationDescription(locationDescription:String) async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_POST_MODEL)?\(LOC_DESCRIPTION_PARAM)=\(locationDescription)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode([Post].self, from: data)
    }
    
    // Fetches posts by a particular author
    static func fetchPostsByAuthor(userId:Int) async throws -> [Post] {
        let url = "\(Env.BASE_URL)\(PATH_TO_POST_MODEL)?\(AUTHOR_PARAM)=\(userId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostErrors(data: data, response: response)
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
        let url = "\(Env.BASE_URL)\(PATH_TO_POST_MODEL)"
        let post = Post(title: title,
                        body: text,
                        location_description: locationDescription,
                        latitude: latitude,
                        longitude: longitude,
                        timestamp: timestamp,
                        author: author)
        let json = try JSONEncoder().encode(post)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterPostErrors(data: data, response: response)
        return try JSONDecoder().decode(Post.self, from: data)
    }
    
    // Deletes post from the database
    static func deletePost(post_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_POST_MODEL)\(post_id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterPostErrors(data: data, response: response)
    }
}
