//
//  CommentFlagAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 7/26/22.
//

import Foundation

struct CommentFlagError: Codable {
    let flagger: [String]?
    let comment: [String]?
    
    let non_field_errors: [String]?
    let detail: [String]?
}

class CommentFlagAPI {
    static let PATH_TO_FLAG_MODEL = "api/comment-flags/"
    static let FLAGGER_PARAM = "flagger"
    static let COMMENT_PARAM = "comment"
    
    static let COMMENT_FLAG_RECOVERY_MESSAGE = "Please try again."
    
    static func filterCommentFlagErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(CommentFlagError.self, from: data)
            
            if let flaggerErrors = error.flagger,
               let flaggerError = flaggerErrors.first {
                throw APIError.ClientError(flaggerError, COMMENT_FLAG_RECOVERY_MESSAGE)
            }
            if let commentErrors = error.comment,
               let commentError = commentErrors.first {
                throw APIError.ClientError(commentError, COMMENT_FLAG_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func fetchFlagsByCommentId(commentId:Int) async throws -> [CommentFlag] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FLAG_MODEL)?\(COMMENT_PARAM)=\(commentId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterCommentFlagErrors(data: data, response: response)
        return try JSONDecoder().decode([CommentFlag].self, from: data)
    }
    
    static func fetchFlagsByFlagger(flaggerId:Int) async throws -> [CommentFlag] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FLAG_MODEL)?\(FLAGGER_PARAM)=\(flaggerId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterCommentFlagErrors(data: data, response: response)
        return try JSONDecoder().decode([CommentFlag].self, from: data)
    }

    static func postFlag(flaggerId:Int, commentId:Int) async throws -> CommentFlag {
        let url = "\(Env.BASE_URL)\(PATH_TO_FLAG_MODEL)"
        let params = [
            FLAGGER_PARAM: flaggerId,
            COMMENT_PARAM: commentId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterCommentFlagErrors(data: data, response: response)
        return try JSONDecoder().decode(CommentFlag.self, from: data)
    }
    
    static func deleteFlag(flaggerId:Int, commentId:Int) async throws {
        let flags = try await fetchFlagsByFlagger(flaggerId: flaggerId)
        for flag in flags {
            if flag.comment == commentId {
                let _ = try await deleteFlag(flag_id: flag.id)
                break
            }
        }
    }

    static func deleteFlag(flag_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_FLAG_MODEL)\(flag_id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterCommentFlagErrors(data: data, response: response)
    }
}
