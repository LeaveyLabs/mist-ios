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
    static func fetchProfiles(text:String) async throws -> [Profile] {
        let url = "https://mist-backend.herokuapp.com/api/profiles?text=\(text)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([Profile].self, from: data)
    }
    
    static func postProfilePic(image:UIImage, profile:Profile) async throws -> Profile {
        let imgData = image.pngData()

        let parameters = [
            "username": profile.username,
            "first_name": profile.first_name,
            "last_name": profile.last_name,
            "user": String(profile.user),
        ]

        let request = AF.upload(
            multipartFormData:
                { multipartFormData in
                    multipartFormData.append(imgData!, withName: "picture", fileName: "\(profile.username).png", mimeType: "image/png")
                       for (key, value) in parameters {
                            multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                        }
                },
            to: "http://127.0.0.1:8000/api/profiles/kevinsun/",
            method: .put
        )
        return try await request.serializingDecodable(Profile.self).value
    }
}
