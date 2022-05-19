//
//  ProfileAPI.swift
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

class ProfileAPI {
    // Fetches all profiles from database (searching for the below text)
    static func fetchProfilesByText(text:String) async throws -> [User] {
        let url = "https://mist-backend.herokuapp.com/api/api-query-user?text=\(text)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([User].self, from: data)
    }
    
    static func fetchProfilesByUsername(username:String) async throws -> [User] {
        let url = "https://mist-backend.herokuapp.com/api/api-query-user?username=\(username)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([User].self, from: data)
    }
    
    static func patchProfilePic(image:UIImage, user:User) async throws -> User {
        let imgData = image.pngData()

        let parameters = [
            "email": user.email,
        ]

        let request = AF.upload(
            multipartFormData:
                { multipartFormData in
                    multipartFormData.append(imgData!, withName: "picture", fileName: "\(user.username).png", mimeType: "image/png")
                       for (key, value) in parameters {
                            multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                        }
                },
            to: "https://mist-backend.herokuapp.com/api-modify-user/",
            method: .put
        )
        return try await request.serializingDecodable(User.self).value
    }
}
