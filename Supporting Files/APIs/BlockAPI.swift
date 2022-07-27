//
//  BlockAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

struct BlockError: Codable {
    let blocking_user: [String]?
    let blocked_user: [String]?
    // Error
    let non_field_errors: [String]?
    let detail: [String]?
}

class BlockAPI {
    static let PATH_TO_BLOCK_MODEL = "api/blocks/"
    static let PATH_TO_CUSTOM_DELETE_BLOCK_ENDPOINT = "api/delete-block/"
    static let BLOCKING_USER_PARAM = "blocking_user"
    static let BLOCKED_USER_PARAM = "blocked_user"
    // Error Recovery Messages
    static let BLOCK_RECOVERY_MESSAGE = "Please try again."
    
    static func filterBlockErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(BlockError.self, from: data)
            
            if let blockingUserErrors = error.blocking_user,
               let blockingUserError = blockingUserErrors.first {
                throw APIError.ClientError(blockingUserError, BLOCK_RECOVERY_MESSAGE)
            }
            if let blockedUserErrors = error.blocked_user,
               let blockedUserError = blockedUserErrors.first {
                throw APIError.ClientError(blockedUserError, BLOCK_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func fetchBlocksByBlockingUser(blockingUserId:Int) async throws -> [Block] {
        let url = "\(Env.BASE_URL)\(PATH_TO_BLOCK_MODEL)?\(BLOCKING_USER_PARAM)=\(blockingUserId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterBlockErrors(data: data, response: response)
        return try JSONDecoder().decode([Block].self, from: data)
    }
    
    static func fetchBlocksByBlockedUser(blockedUserId:Int) async throws -> [Block] {
        let url = "\(Env.BASE_URL)\(PATH_TO_BLOCK_MODEL)?\(BLOCKED_USER_PARAM)=\(blockedUserId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterBlockErrors(data: data, response: response)
        return try JSONDecoder().decode([Block].self, from: data)
    }
    
    static func postBlock(blockingUserId:Int, blockedUserId:Int) async throws -> Block {
        let url = "\(Env.BASE_URL)\(PATH_TO_BLOCK_MODEL)"
        let params = [
            BLOCKING_USER_PARAM: blockingUserId,
            BLOCKED_USER_PARAM: blockedUserId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterBlockErrors(data: data, response: response)
        return try JSONDecoder().decode(Block.self, from: data)
    }
    
    static func deleteBlock(blockingUserId:Int, blockedUserId:Int) async throws {
        let endpoint = "\(Env.BASE_URL)\(PATH_TO_CUSTOM_DELETE_BLOCK_ENDPOINT)"
        let params = "\(BLOCKING_USER_PARAM)=\(blockingUserId)&\(BLOCKED_USER_PARAM)=\(blockedUserId)"
        let url = "\(endpoint)?\(params)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterBlockErrors(data: data, response: response)
    }
    
    static func deleteBlock(block_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_BLOCK_MODEL)\(block_id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterBlockErrors(data: data, response: response)
    }
}
