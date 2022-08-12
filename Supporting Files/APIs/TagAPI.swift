//
//  TagAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 8/3/22.
//

import Foundation

struct TagError: Codable {
    let comment: [String]?
    let tagged_name: [String]?
    let tagging_user: [String]?
    let tagged_user: [String]?
    let tagged_phone_number: [String]?
    
    let non_field_errors: [String]?
    let detail: String?
}

struct TagParams: Codable {
    let comment: Int
    let tagged_name: String
    let tagging_user: Int
    let tagged_user: Int?
    let tagged_phone_number: String?
    
}

class TagAPI {
    static let PATH_TO_TAG_MODEL = "api/tags/"
    
    static let TAG_RECOVERY_MESSAGE = "Please try again."
    
    static func filterTagErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(TagError.self, from: data)
            
            if let commentErrors = error.comment,
               let commentError = commentErrors.first {
                throw APIError.ClientError(commentError, TAG_RECOVERY_MESSAGE)
            }
            if let taggedNameErrors = error.tagged_name,
               let taggedNameError = taggedNameErrors.first {
                throw APIError.ClientError(taggedNameError, TAG_RECOVERY_MESSAGE)
            }
            if let taggingUserErrors = error.tagging_user,
               let taggingUserError = taggingUserErrors.first {
                throw APIError.ClientError(taggingUserError, TAG_RECOVERY_MESSAGE)
            }
            if let taggedUserErrors = error.tagged_user,
               let taggedUserError = taggedUserErrors.first {
                throw APIError.ClientError(taggedUserError, TAG_RECOVERY_MESSAGE)
            }
            if let taggedPhoneNumberErrors = error.tagged_phone_number,
               let taggedPhoneNumberError = taggedPhoneNumberErrors.first {
                throw APIError.ClientError(taggedPhoneNumberError, TAG_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func fetchTags() async throws -> [Tag] {
        let url = "\(Env.BASE_URL)\(PATH_TO_TAG_MODEL)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterTagErrors(data: data, response: response)
        return try JSONDecoder().decode([Tag].self, from: data)
    }
    
    static func postTag(comment:Int,
                        tagged_name:String,
                        tagging_user:Int,
                        tagged_user:Int) async throws -> Tag {
        let url = "\(Env.BASE_URL)\(PATH_TO_TAG_MODEL)"
        let params = TagParams(comment: comment,
                               tagged_name: tagged_name,
                               tagging_user: tagging_user,
                               tagged_user: tagging_user,
                               tagged_phone_number: nil)
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterTagErrors(data: data, response: response)
        return try JSONDecoder().decode(Tag.self, from: data)
    }
    
    static func postTag(comment:Int,
                        tagged_name:String,
                        tagging_user:Int,
                        tagged_phone_number: String) async throws -> Tag {
        let url = "\(Env.BASE_URL)\(PATH_TO_TAG_MODEL)"
        let params = TagParams(comment: comment,
                               tagged_name: tagged_name,
                               tagging_user: tagging_user,
                               tagged_user: nil,
                               tagged_phone_number: tagged_phone_number)
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterTagErrors(data: data, response: response)
        return try JSONDecoder().decode(Tag.self, from: data)
    }
    
    static func batchPostTags(comment:Int, tags: [Tag]) async throws -> [Tag] {
        var syncedTags = [Tag]()
        try await withThrowingTaskGroup(of: Tag?.self) { group in
            for tag in tags {
                group.addTask {
                    if let tagged_user = tag.tagged_user {
                        return try await TagAPI.postTag(comment: comment, tagged_name: tag.tagged_name, tagging_user: tag.tagging_user, tagged_user: tagged_user)
                    } else {
                        guard let tagged_number = tag.tagged_phone_number else { return nil }
                        return try await TagAPI.postTag(comment: comment, tagged_name: tag.tagged_name, tagging_user: tag.tagging_user, tagged_phone_number: tagged_number)
                    }
                }
            }
            for try await tag in group {
                guard let successfulTag = tag else { return }
                syncedTags.append(successfulTag)
            }
        }
        return syncedTags
    }
    
    static func deleteTag(id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_TAG_MODEL)\(id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterTagErrors(data: data, response: response)
    }
}
