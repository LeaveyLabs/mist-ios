//
//  FlagAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

struct PostFlagError: Codable {
    let flagger: [String]?
    let post: [String]?
    
    let non_field_errors: [String]?
    let detail: [String]?
}

class PostFlagAPI {
    static let PATH_TO_FLAG_MODEL = "api/post-flags/"
    static let FLAGGER_PARAM = "flagger"
    static let POST_PARAM = "post"
    
    static let POST_FLAG_RECOVERY_MESSAGE = "Please try again later"
    
    static func filterPostFlagErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(PostFlagError.self, from: data)
            
            if let flaggerErrors = error.flagger,
               let flaggerError = flaggerErrors.first {
                throw APIError.ClientError(flaggerError, POST_FLAG_RECOVERY_MESSAGE)
            }
            if let postErrors = error.post,
               let postError = postErrors.first {
                throw APIError.ClientError(postError, POST_FLAG_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func fetchFlagsByPostId(postId:Int) async throws -> [PostFlag] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FLAG_MODEL)?\(POST_PARAM)=\(postId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostFlagErrors(data: data, response: response)
        return try JSONDecoder().decode([PostFlag].self, from: data)
    }
    
    static func fetchFlagsByFlagger(flaggerId:Int) async throws -> [PostFlag] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FLAG_MODEL)?\(FLAGGER_PARAM)=\(flaggerId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterPostFlagErrors(data: data, response: response)
        return try JSONDecoder().decode([PostFlag].self, from: data)
    }

    static func postFlag(flaggerId:Int, postId:Int) async throws -> PostFlag {
        let url = "\(Env.BASE_URL)\(PATH_TO_FLAG_MODEL)"
        let params = [
            FLAGGER_PARAM: flaggerId,
            POST_PARAM: postId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterPostFlagErrors(data: data, response: response)
        return try JSONDecoder().decode(PostFlag.self, from: data)
    }
    
    static func deleteFlag(flaggerId:Int, postId:Int) async throws {
        let flags = try await fetchFlagsByFlagger(flaggerId: flaggerId)
        for flag in flags {
            if flag.post == postId {
                let _ = try await deleteFlag(flag_id: flag.id)
                break
            }
        }
    }

    static func deleteFlag(flag_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_FLAG_MODEL)\(flag_id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterPostFlagErrors(data: data, response: response)
    }
}

