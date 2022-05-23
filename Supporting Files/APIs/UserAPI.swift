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
    static func fetchUsersByText(text:String) async throws -> [User] {
        let url = "https://mist-backend.herokuapp.com/api/users?text=\(text)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([User].self, from: data)
    }
    
    static func fetchAuthedUsersByUsername(username:String) async throws -> [AuthedUser] {
        let url = "https://mist-backend.herokuapp.com/api/users?username=\(username)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([AuthedUser].self, from: data)
    }
    
    static func fetchUsersByUsername(username:String) async throws -> [User] {
        let url = "https://mist-backend.herokuapp.com/api/users?username=\(username)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([User].self, from: data)
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
}
