//
//  WordAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation

class WordAPI {
    static let PATH_TO_WORD_MODEL = "api/words/"
    static let SEARCH_WORD_PARAM = "search_word"
    static let WRAPPER_WORDS_PARAM = "wrapper_words"
    
    static func fetchWords(search_word:String, wrapper_words:[String]) async throws -> [Word] {
        var url = "\(BASE_URL)\(PATH_TO_WORD_MODEL)?"
        for wrapper_word in wrapper_words {
            url += "\(WRAPPER_WORDS_PARAM)=\(wrapper_word)&"
        }
        url += "\(SEARCH_WORD_PARAM)=\(search_word)"
        print(url)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Word].self, from: data)
    }
    
}
