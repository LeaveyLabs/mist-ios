//
//  UserAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation
import UIKit
import Alamofire

extension NSMutableData {
  func appendString(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}

//https://github.com/kean/Nuke


class UserAPI {
    static let PATH_TO_USER_MODEL = "api/users/"
    static let PATH_TO_MATCHES = "api/matches/"
    static let PATH_TO_FRIENDSHIPS = "api/friendships/"
    static let EMAIL_PARAM = "email"
    static let USERNAME_PARAM = "username"
    static let PASSWORD_PARAM = "password"
    static let FIRST_NAME_PARAM = "first_name"
    static let LAST_NAME_PARAM = "last_name"
    static let TEXT_PARAM = "text"
    static let TOKEN_PARAM = "token"
    static let AUTH_HEADERS:HTTPHeaders = [
        "Authorization": "Token \(getGlobalAuthToken())"
    ]
    
    static func fetchFriends() async throws -> [ReadOnlyUser] {
        let url = "\(BASE_URL)\(PATH_TO_FRIENDSHIPS)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchMatches() async throws -> [ReadOnlyUser] {
        let url = "\(BASE_URL)\(PATH_TO_MATCHES)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchUsersByUserId(userId:Int) async throws -> ReadOnlyUser {
        let url = "\(BASE_URL)\(PATH_TO_USER_MODEL)\(userId)/"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode(ReadOnlyUser.self, from: data)
    }
    
    static func fetchUsersByUsername(username:String) async throws -> [ReadOnlyUser] {
        let url = "\(BASE_URL)\(PATH_TO_USER_MODEL)?\(USERNAME_PARAM)=\(username)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchUsersByFirstName(firstName:String) async throws -> [ReadOnlyUser] {
        let url = "\(BASE_URL)\(PATH_TO_USER_MODEL)?\(FIRST_NAME_PARAM)=\(firstName)"
        print(url)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchUsersByLastName(lastName:String) async throws -> [ReadOnlyUser] {
        let url = "\(BASE_URL)\(PATH_TO_USER_MODEL)?\(LAST_NAME_PARAM)=\(lastName)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchUsersByText(containing text:String) async throws -> [ReadOnlyUser] {
        let url = "\(BASE_URL)\(PATH_TO_USER_MODEL)?\(TEXT_PARAM)=\(text)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchAuthedUserByToken(token:String) async throws -> CompleteUser {
        let url = "\(BASE_URL)\(PATH_TO_USER_MODEL)?\(TOKEN_PARAM)=\(token)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        let queriedUsers = try JSONDecoder().decode([CompleteUser].self, from: data)
        let tokenUser = queriedUsers[0]
        return tokenUser
    }
    
    static func patchProfilePic(image:UIImage, id:Int, username:String) async throws -> CompleteUser {
        let imgData = image.pngData()
        
        let request = AF.upload(
            multipartFormData:
                { multipartFormData in
                    multipartFormData.append(imgData!, withName: "picture", fileName: "\(username).png", mimeType: "image/png")
                },
            to: "\(BASE_URL)\(PATH_TO_USER_MODEL)\(id)/",
            method: .patch,
            headers: AUTH_HEADERS
        )
        
        let response = await request.serializingDecodable(CompleteUser.self).response
        let authedUser = try await request.serializingDecodable(CompleteUser.self).value
        
        if let httpResponse = response.response {
            let goodRequest = (200...299).contains(httpResponse.statusCode)
            let badRequest = (400...499).contains(httpResponse.statusCode)
            
            if goodRequest {
                return authedUser
            }
            else if badRequest {
                throw APIError.InvalidCredentials
            }
            else {
                throw APIError.Unknown
            }
        } else {
            throw APIError.NoResponse
        }
    }
    
    static func patchUsername(username:String, id:Int) async throws -> CompleteUser {
        let url =  "\(BASE_URL)\(PATH_TO_USER_MODEL)\(id)/"
        let params:[String:String] = [USERNAME_PARAM: username]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.PATCH.rawValue)
        return try JSONDecoder().decode(CompleteUser.self, from: data)
    }
    
    static func patchPassword(password:String, id:Int) async throws -> CompleteUser {
        let url =  "\(BASE_URL)\(PATH_TO_USER_MODEL)\(id)/"
        let params:[String:String] = [PASSWORD_PARAM: password]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.PATCH.rawValue)
        return try JSONDecoder().decode(CompleteUser.self, from: data)
    }
    
    static func deleteUser(id:Int) async throws {
        let url =  "\(BASE_URL)\(PATH_TO_USER_MODEL)\(id)/"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
    
    static func UIImageFromURLString(url:String?) async throws -> UIImage {
        guard let url = url else {
            return UIImage(systemName: "person.crop.circle")!
        }

        let (data, _) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return UIImage(data: data) ?? UIImage(systemName: "person.crop.circle")!
    }
}
