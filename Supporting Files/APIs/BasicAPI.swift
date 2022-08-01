//
//  BasicAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

var AUTHTOKEN = ""

func setGlobalAuthToken(token:String) {
    AUTHTOKEN = token
}

func getGlobalAuthToken() -> String {
    return AUTHTOKEN
}

func isSuccess(statusCode:Int) -> Bool {
    return (200...299).contains(statusCode)
}

func isClientError(statusCode:Int) -> Bool {
    return (400...499).contains(statusCode)
}

func isServerError(statusCode:Int) -> Bool {
    return (500...599).contains(statusCode)
}

enum HTTPMethods: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

class BasicAPI {
    static func filterBasicErrors(data: Data, response: HTTPURLResponse) throws {
        let clientError = (400...499).contains(response.statusCode)
        let serverError = (500...599).contains(response.statusCode)
        
        if clientError {
            if response.statusCode == 401 {
                throw APIError.Unauthorized
            }
            else if response.statusCode == 403 {
                throw APIError.Forbidden
            }
            else if response.statusCode == 404 {
                throw APIError.NotFound
            }
            else if response.statusCode == 408 {
                throw APIError.Timeout
            }
            else if response.statusCode == 429 {
                throw APIError.Throttled
            }
        } else if serverError {
            throw APIError.ServerError
        }
    }
    
    static func runRequest(request:URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            throw APIError.CouldNotConnect
        }
        if let httpResponse = (response as? HTTPURLResponse) {
            try filterBasicErrors(data: data, response: httpResponse)
            return (data, httpResponse)
        } else {
            throw APIError.NoResponse
        }
    }
    
    static func formatURLRequest(url:String, method:String, body:Data, headers:[String:String]) throws -> URLRequest {
        let serviceUrl = URL(string: url)!
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = method
        request.httpBody = body
        for (header, value) in headers {
            request.setValue(value, forHTTPHeaderField: header)
        }
        return request
    }
    
    static func basicHTTPCallWithoutToken(url:String, jsonData:Data, method:String) async throws -> (Data, HTTPURLResponse) {
        let request = try formatURLRequest(url: url,
                                       method: method,
                                       body: jsonData,
                                       headers: ["Content-Type": "application/json"])
        return try await runRequest(request: request)
    }
    
    static func baiscHTTPCallWithToken(url:String, jsonData:Data, method:String) async throws -> (Data, HTTPURLResponse) {
        let request = try formatURLRequest(url: url,
                                       method: method,
                                       body: jsonData,
                                       headers: [
                                        "Content-Type": "application/json",
                                        "Authorization": "Token \(getGlobalAuthToken())",
                                       ])
        return try await runRequest(request: request)
    }
}
