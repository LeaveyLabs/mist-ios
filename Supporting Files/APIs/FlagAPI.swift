//
//  FlagAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

class FlagAPI {
    static let PATH_TO_FLAG_MODEL = "api/flags/"
    static let FLAGGER_PARAM = "flagger"
    static let POST_PARAM = "post"
    
    static func fetchFlagsByPostId(postId:Int) async throws -> [Flag] {
        let url = "\(BASE_URL)\(PATH_TO_FLAG_MODEL)?\(POST_PARAM)=\(postId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Flag].self, from: data)
    }
    
    static func fetchFlagsByFlagger(flaggerId:Int) async throws -> [Flag] {
        let url = "\(BASE_URL)\(PATH_TO_FLAG_MODEL)?\(FLAGGER_PARAM)=\(flaggerId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Flag].self, from: data)
    }

    static func postFlag(flaggerId:Int, postId:Int) async throws -> Flag {
        let url = "\(BASE_URL)\(PATH_TO_FLAG_MODEL)"
        let params = [
            FLAGGER_PARAM: flaggerId,
            POST_PARAM: postId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(Flag.self, from: data)
    }

    static func deleteFlag(flag_id:Int) async throws {
        let url = "\(BASE_URL)\(PATH_TO_FLAG_MODEL)\(flag_id)/"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
}

