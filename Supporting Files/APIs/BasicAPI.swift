//
//  BasicAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

enum APIError: Error {
    case badAPIEndPoint
    case badId
}

class BasicAPI {
    // GET from the URL (url) with the HTTP body (data)
    static func fetch(url:String) async throws -> Data {
        // Initialize API endpoint
        guard let serviceUrl = URL(string:url) else {
            throw APIError.badAPIEndPoint
        }
        // Initialize API request
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "GET"
        // Run API request
        let (data, response) = try await URLSession.shared.data(for: request)
        // Throw if unsuccessful
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw CommentError.badId
        }
        // Deserialize data and return result
        return data
    }
    
    // POST to the URL (url) with the HTTP body (data)
    static func post(url:String, jsonData:Data) async throws -> Data {
        // Intiailize API endpoint
        guard let serviceUrl = URL(string:url) else {
            throw APIError.badAPIEndPoint
        }
        // Prepare API request and JSON-formmatted comment
        var request = URLRequest(url: serviceUrl)
        // Specify POST + HTTP Headers
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Run the request
        let (data, response) = try await URLSession.shared.data(for: request)
        return data
    }
    
    // DELETE from the URL (url) with the HTTP body (data)
    static func delete(url:String, jsonData:Data) async throws -> Data {
        // Intiailize API endpoint
        guard let serviceUrl = URL(string:url) else {
            throw APIError.badAPIEndPoint
        }
        // Prepare API request and JSON-formmatted comment
        var request = URLRequest(url: serviceUrl)
        // Specify POST + HTTP Headers
        request.httpMethod = "DELETE"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Run the request
        let (data, response) = try await URLSession.shared.data(for: request)
        return data
    }
}
