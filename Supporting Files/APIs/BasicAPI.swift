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

var AUTHTOKEN = ""

func setGlobalAuthToken(token:String) {
    AUTHTOKEN = token
}

func getGlobalAuthToken() -> String {
    return AUTHTOKEN
}

class BasicAPI {
    static func baiscHTTPCallWithToken(url:String, jsonData:Data, method:String) async throws -> (Data, URLResponse) {
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
    
    static func basicHTTPCallWithoutToken(url:String, jsonData:Data, method:String) async throws -> (Data, URLResponse) {
        // Initialize API endpoint
        guard let serviceUrl = URL(string:url) else {
            throw APIError.badAPIEndPoint
        }
        // Initialize API request
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = method
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Run API request
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, response)
    }
}
