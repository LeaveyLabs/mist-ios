//
//  BasicAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

enum APIError: Error {
    case badAPIEndPoint
}

let AUTHTOKEN = "fb313fe42682f723f3312908ae1279c4f4289535"

func setGlobalAuthToken(token:String) {
    AUTHTOKEN = token
}

func getGlobalAuthToken() {
    return AUTHTOKEN
}

class BasicAPI {
    static func basicHTTPCall(url:String, jsonData:Data, method:String) -> (Data, HTTPURLResponse) {
        // Initialize API endpoint
        guard let serviceUrl = URL(string:url) else {
            throw APIError.badAPIEndPoint
        }
        // Initialize API request
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = method
        request.httpBody = jsonData
        request.setValue("Token \(getGlobalAuthToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Run API request
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, response)
    }
    
    // GET from the URL (url) with the HTTP body (data)
    static func fetch(url:String) async throws -> (Data, HTTPURLResponse) {
        return basicHTTPCall(url: url, jsonData: Data(), method: "GET")
    }
    
    // POST to the URL (url) with the HTTP body (data)
    static func post(url:String, jsonData:Data) async throws -> (Data, HTTPURLResponse) {
        return basicHTTPCall(url: url, jsonData: jsonData, method: "POST")
    }
    
    // PATCH to the URL (url) with the HTTP body (data)
    static func patch(url:String, jsonData:Data) async throws -> (Data, HTTPURLResponse) {
        return basicHTTPCall(url: url, jsonData: jsonData, method: "PATCH")
    }
    
    // DELETE from the URL (url) with the HTTP body (data)
    static func delete(url:String, jsonData:Data) async throws -> (Data, HTTPURLResponse) {
        return basicHTTPCall(url: url, jsonData: jsonData, method: "DELETE")
    }
}
