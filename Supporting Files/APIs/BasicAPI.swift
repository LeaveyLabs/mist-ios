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
    case generic
}

let AUTHTOKEN = "eb622f9ac993c621391de3418bc18f19cb563a61"

func retrieveToken() -> String {
    return AUTHTOKEN
}

class BasicAPI {
    // GET from the URL (url) with the HTTP body (data)
    static func fetch(url:String, authToken:String?) async throws -> Data {
        // Initialize API endpoint
        guard let serviceUrl = URL(string:url) else {
            throw APIError.badAPIEndPoint
        }
        // Initialize API request
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "GET"
        request.setValue("Token \(retrieveToken())", forHTTPHeaderField: "Authorization")
        // Run API request
        let (data, response) = try await URLSession.shared.data(for: request)
        // Throw if unsuccessful
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.badId
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
        request.setValue("Token \(retrieveToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Run the request
        let (data, response) = try await URLSession.shared.data(for: request)
        return data
    }
    
    // DELETE from the URL (url) with the HTTP body (data)
    static func delete(url:String, jsonData:Data, authToken:String?) async throws -> Data {
        // Intiailize API endpoint
        guard let serviceUrl = URL(string:url) else {
            throw APIError.badAPIEndPoint
        }
        // Prepare API request and JSON-formmatted comment
        var request = URLRequest(url: serviceUrl)
        // Specify POST + HTTP Headers
        request.httpMethod = "DELETE"
        request.httpBody = jsonData
        request.setValue("Token \(retrieveToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Run the request
        let (data, response) = try await URLSession.shared.data(for: request)
        return data
    }
}
