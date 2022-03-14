//
//  ProfileAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation

class ProfileAPI {
    // Fetches all profiles from database (searching for the below text)
    static func fetchProfiles(text:String) async throws -> [Profile] {
        let url = "https://mist-backend.herokuapp.com/api/profiles?text=\(text)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([Profile].self, from: data)
    }
}
