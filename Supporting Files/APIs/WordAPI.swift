//
//  WordAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation

class WordAPI {
    static let PATH_TO_WORD_MODEL = "api/words/"
    static let TEXT_PARAM = "text"
    // Fetches all words from database (searching for the below text)
    static func fetchWords(text:String) async throws -> [Word] {
        let url = "\(BASE_URL)\(PATH_TO_WORD_MODEL)?\(TEXT_PARAM)=\(text)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Word].self, from: data)
    }
}
