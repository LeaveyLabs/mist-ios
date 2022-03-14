//
//  WordAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation

class WordAPI {
    // Fetches all words from database (searching for the below text)
    static func fetchWords(text:String) async throws -> [Word] {
        let url = "https://mist-backend.herokuapp.com/api/words?text=\(text)"
        let data = try await BasicAPI.fetch(url:url)
        return try JSONDecoder().decode([Word].self, from: data)
    }
}
