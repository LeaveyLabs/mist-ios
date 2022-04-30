//
//  ProfileAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation
import UIKit

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
    
    static func postProfilePic(image:UIImage, profile:Profile) async throws -> Void {
        /*
         Taken from: https://www.donnywals.com/uploading-images-and-forms-to-a-server-using-urlsession/
         */
        let imageData = image.pngData()!
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: URL(string: "https://mist-backend.herokuapp.com/api/profiles/\(profile.username)/")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = NSMutableData()

        httpBody.appendString(convertFormField(named: "username", value: profile.username, using: boundary))
        httpBody.appendString(convertFormField(named: "first_name", value: profile.first_name, using: boundary))
        httpBody.appendString(convertFormField(named: "last_name", value: profile.last_name, using: boundary))

        httpBody.append(convertFileData(fieldName: "picture",
                                        fileName: "\(profile.username).png",
                                        mimeType: "image/png",
                                        fileData: imageData,
                                        using: boundary))

        httpBody.appendString("--\(boundary)--")

        request.httpBody = httpBody as Data

        print(String(data: httpBody as Data, encoding: .utf8)!)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
          // handle the response here
        }.resume()
        
    }
    
    private static func convertFormField(named name: String, value: String, using boundary: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

      return fieldString
    }
    
    private static func convertFileData(fieldName: String, fileName: String, mimeType: String, fileData: Data, using boundary: String) -> Data {
        let data = NSMutableData()

        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        data.appendString("Content-Type: \(mimeType)\r\n\r\n")
        data.append(fileData)
        data.appendString("\r\n")

        return data as Data
    }

    
}
