//
//  BlockAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

class BlockAPI {
    static let PATH_TO_BLOCK_MODEL = "api/blocks/"
    static let PATH_TO_CUSTOM_DELETE_BLOCK_ENDPOINT = "api/delete-block/"
    static let BLOCKING_USER_PARAM = "blocking_user"
    static let BLOCKED_USER_PARAM = "blocked_user"
    
    static func fetchBlocksByBlockingUser(blockingUserId:Int) async throws -> [Block] {
        let url = "\(BASE_URL)\(PATH_TO_BLOCK_MODEL)?\(BLOCKING_USER_PARAM)=\(blockingUserId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Block].self, from: data)
    }
    
    static func fetchBlocksByBlockedUser(blockedUserId:Int) async throws -> [Block] {
        let url = "\(BASE_URL)\(PATH_TO_BLOCK_MODEL)?\(BLOCKED_USER_PARAM)=\(blockedUserId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Block].self, from: data)
    }
    
    static func postBlock(blockingUserId:Int, blockedUserId:Int) async throws -> Block {
        let url = "\(BASE_URL)\(PATH_TO_BLOCK_MODEL)"
        let params = [
            BLOCKING_USER_PARAM: blockingUserId,
            BLOCKED_USER_PARAM: blockingUserId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(Block.self, from: data)
    }
    
    static func deleteBlock(blockingUserId:Int, blockedUserId:Int) async throws {
        let endpoint = "\(BASE_URL)\(PATH_TO_CUSTOM_DELETE_BLOCK_ENDPOINT)"
        let params = "\(BLOCKING_USER_PARAM)=\(blockingUserId)&\(BLOCKED_USER_PARAM)=\(blockedUserId)"
        let url = "\(endpoint)?\(params)"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
    
    static func deleteBlock(block_id:Int) async throws {
        let url = "\(BASE_URL)\(PATH_TO_BLOCK_MODEL)\(block_id)/"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
}
