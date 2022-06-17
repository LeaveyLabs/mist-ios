//
//  BasicAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

enum APIError: Error {
    case CouldNotConnect
    case ServerError
    case InvalidParameters
    case InvalidCredentials
    case NotFound
    case Timeout
    case Throttled
    case NoResponse
    case Unknown
}

var AUTHTOKEN = ""

func setGlobalAuthToken(token:String) {
    AUTHTOKEN = token
}

func getGlobalAuthToken() -> String {
    return AUTHTOKEN
}

//var BASE_URL = ProcessInfo.processInfo.environment["BASE_URL"]!
var BASE_URL = "https://mist-backend-test.herokuapp.com/"

enum HTTPMethods: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

class BasicAPI {
    static func basicHTTPCallWithoutToken(url:String, jsonData:Data, method:String) async throws -> (Data, URLResponse) {
        let serviceUrl = URL(string:url)!
        var request = URLRequest(url: serviceUrl)
        // Initialize API request
        request.httpMethod = method
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Run API request
        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            throw APIError.CouldNotConnect
        }

        if let httpResponse = (response as? HTTPURLResponse) {
            let goodRequest = (200...299).contains(httpResponse.statusCode)
            let serverError = (500...599).contains(httpResponse.statusCode)
            if goodRequest {
                return (data, response)
            }
            else if serverError {
                throw APIError.ServerError
            }
            else if httpResponse.statusCode == 400 {
                throw APIError.InvalidParameters
            }
            else if httpResponse.statusCode == 403 {
                throw APIError.InvalidCredentials
            }
            else if httpResponse.statusCode == 404 {
                throw APIError.NotFound
            }
            else if httpResponse.statusCode == 408 {
                throw APIError.Timeout
            }
            else if httpResponse.statusCode == 429 {
                throw APIError.Throttled
            }
            else {
                throw APIError.Unknown
            }
        } else {
            throw APIError.NoResponse
        }
    }
    
    static func baiscHTTPCallWithToken(url:String, jsonData:Data, method:String) async throws -> (Data, URLResponse) {        let serviceUrl = URL(string:url)!
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = method
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(getGlobalAuthToken())", forHTTPHeaderField: "Authorization")
        // Run API request
        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            throw APIError.CouldNotConnect
        }
        
        if let httpResponse = (response as? HTTPURLResponse) {
            let goodRequest = (200...299).contains(httpResponse.statusCode)
            let serverError = (500...599).contains(httpResponse.statusCode)
            if goodRequest {
                return (data, response)
            }
            else if serverError {
                throw APIError.ServerError
            }
            else if httpResponse.statusCode == 400 {
                throw APIError.InvalidParameters
            }
            else if httpResponse.statusCode == 403 {
                throw APIError.InvalidCredentials
            }
            else if httpResponse.statusCode == 404 {
                throw APIError.NotFound
            }
            else if httpResponse.statusCode == 408 {
                throw APIError.Timeout
            }
            else if httpResponse.statusCode == 429 {
                throw APIError.Throttled
            }
            else {
                throw APIError.Unknown
            }
        } else {
            throw APIError.NoResponse
        }
    }
}
