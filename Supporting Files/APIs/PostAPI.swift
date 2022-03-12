// Acquires posts from the datbase

import Foundation

enum PostError: Error {
    case badAPIEndPoint
    case badId
}

class PostAPI {
    static func fetchPosts() async throws -> [Post] {
        guard let url = URL(string: "https://mist-backend.herokuapp.com/api/posts/") else {
            throw PostError.badAPIEndPoint
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw PostError.badId
        }
        let result = try JSONDecoder().decode([Post].self, from: data)
        return result
    }

    // Creates post in the database
    static func createPost(post:Post) async throws {
        guard let serviceUrl = URL(string: "https://mist-backend.herokuapp.com/api/posts/") else {
            throw PostError.badAPIEndPoint
        }
        var request = URLRequest(url: serviceUrl)
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(post)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try await URLSession.shared.data(for: request)
    }

}
