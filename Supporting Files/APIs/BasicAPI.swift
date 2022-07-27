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

enum HTTPMethods: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

class BasicAPI {
    static func filterBasicErrors(data: Data, response: URLResponse) async throws {
        if let httpResponse = (response as? HTTPURLResponse) {
            let clientError = (400...499).contains(httpResponse.statusCode)
            let serverError = (500...599).contains(httpResponse.statusCode)
            
            if clientError {
                print(String(data: data, encoding: String.Encoding.utf8) as Any)
                if httpResponse.statusCode == 400 {
                    throw APIError.InvalidParameters
                }
                else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
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
            } else if serverError {
                throw APIError.ServerError
            }
        } else {
            throw APIError.NoResponse
        }
    }
    
    static func runRequest(request:URLRequest) async throws -> (Data, URLResponse) {
        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            throw APIError.CouldNotConnect
        }
        try await filterBasicErrors(data: data, response: response)
        return (data, response)
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
    
    static func basicHTTPCallWithoutToken(url:String, jsonData:Data, method:String) async throws -> (Data, URLResponse) {
        let request = try formatURLRequest(url: url,
                                       method: method,
                                       body: jsonData,
                                       headers: ["Content-Type": "application/json"])
        return try await runRequest(request: request)
    }
    
    static func baiscHTTPCallWithToken(url:String, jsonData:Data, method:String) async throws -> (Data, URLResponse) {
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
