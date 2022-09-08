//
//  WordAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation

struct WordError: Codable {
    let non_field_errors: [String]?
    let detail: [String]?
}

class WordAPI {
    static let PATH_TO_WORD_MODEL = "api/words/"
    static let SEARCH_WORD_PARAM = "search_word"
    static let WRAPPER_WORDS_PARAM = "wrapper_words"
    
    static func filterWordErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        if isSuccess(statusCode: statusCode) { return }
        throw APIError.Unknown
    }
    
    static func fetchWords(search_word:String, wrapper_words:[String]) async throws -> [Word] {
        var url = "\(Env.BASE_URL)\(PATH_TO_WORD_MODEL)?"
        for wrapper_word in wrapper_words {
            url += "\(WRAPPER_WORDS_PARAM)=\(wrapper_word)&"
        }
        url += "\(SEARCH_WORD_PARAM)=\(search_word)"
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterWordErrors(data: data, response: response)
        return try JSONDecoder().decode([Word].self, from: data)
    }
    
}
