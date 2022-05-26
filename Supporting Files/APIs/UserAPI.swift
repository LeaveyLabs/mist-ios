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
    // Fetches all profiles from database (searching for the below text)
    static func fetchUsersByText(containing text:String) async throws -> [User] {
        let url = "https://mist-backend.herokuapp.com/api/users?text=\(text)"
        let (data, response) = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([User].self, from: data)
    }
    
    static func fetchAuthedUsersByUsername(username:String) async throws -> [AuthedUser] {
        let url = "https://mist-backend.herokuapp.com/api/users?username=\(username)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([AuthedUser].self, from: data)
    }
    
    static func fetchUsersByUsername(username:String) async throws -> [User] {
        let url = "https://mist-backend.herokuapp.com/api/users?username=\(username)"
        let (data, response) = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([User].self, from: data)
    }
    
    static func fetchUserByToken(token:String) async throws -> [AuthedUser] {
        let url = "https://mist-backend.herokuapp.com/api/users?token=\(token)"
        let (data, response) = try await BasicAPI.fetch(url:url)
        let queriedUsers = try JSONDecoder().decode([AuthedUser].self, from: data)
        let tokenUser = queriedUsers[0]
        return tokenUser
    }
    
    static func patchProfilePic(image:UIImage, user:AuthedUser) async throws -> AuthedUser {
        let imgData = image.pngData()

        let request = AF.upload(
            multipartFormData:
                { multipartFormData in
                    multipartFormData.append(imgData!, withName: "picture", fileName: "\(user.username).png", mimeType: "image/png")
                },
            to: "https://mist-backend.herokuapp.com/api/users/\(user.id)/",
            method: .patch
        )
        return try await request.serializingDecodable(AuthedUser.self).value
    }
    
    static func patchUsername(username:String, user:AuthedUser) async throws -> AuthedUser {
        let url =  "https://mist-backend.herokuapp.com/api/users/\(user.id)/"
        let obj:[String:String] = [
            "username": username,
        ]
        let json = try JSONEncoder().encode(post)
        let (data, response) = try await BasicAPI.patch(url: url, jsonData: json)
        return try JSONDecoder().decode(AuthedUser.self, from: data)
    }
    
    static func patchPassword(password:String, user:AuthedUser) async throws -> AuthedUser {
        let url =  "https://mist-backend.herokuapp.com/api/users/\(user.id)/"
        let obj:[String:String] = [
            "password": password,
        ]
        let json = try JSONEncoder().encode(post)
        let (data, response) = try await BasicAPI.patch(url: url, jsonData: json)
        return try JSONDecoder().decode(AuthedUser.self, from: data)
    }
    
    static func deleteUser(id:Int) async throws {
        let url =  "https://mist-backend.herokuapp.com/api/users/\(user.id)/"
        let (data, response) = try await BasicAPI.delete(url: url, jsonData: Data())
    }
    
    static func UIImageFromURLString(url:String) async throws -> UIImage {
        return UIImage(data: try await BasicAPI.fetch(url: url))
    }
}
