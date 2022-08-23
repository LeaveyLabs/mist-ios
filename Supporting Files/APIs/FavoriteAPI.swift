//
//  FavoriteAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

struct FavoriteError: Codable {
    let post: [String]?
    let favoriting_user: [String]?
    
    let non_field_errors: [String]?
    let detail: [String]?
}

class FavoriteAPI {
    static let PATH_TO_FAVORITES = "api/favorites/"
    static let PATH_TO_CUSTOM_DELETE_FAVORITE_ENDPOINT = "api/delete-favorite/"
    static let POST_PARAM = "post"
    static let USER_PARAM = "favoriting_user"
    
    static let FAVORITE_RECOVERY_MESSAGE = "Please try again later"
    
    static func filterFavoriteErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(FavoriteError.self, from: data)
            
            if let postErrors = error.post,
               let postError = postErrors.first {
                throw APIError.ClientError(postError, FAVORITE_RECOVERY_MESSAGE)
            }
            if let favoritingUserErrors = error.favoriting_user,
               let favoritingUserError = favoritingUserErrors.first {
                throw APIError.ClientError(favoritingUserError, FAVORITE_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func fetchFavoritesByUser(userId: Int) async throws -> [Favorite] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FAVORITES)?\(USER_PARAM)=\(userId)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterFavoriteErrors(data: data, response: response)
        return try JSONDecoder().decode([Favorite].self, from: data)
    }
    
    static func postFavorite(userId: Int, postId: Int) async throws -> Favorite {
        let url = "\(Env.BASE_URL)\(PATH_TO_FAVORITES)"
        let params = [
            POST_PARAM: postId,
            USER_PARAM: userId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterFavoriteErrors(data: data, response: response)
        return try JSONDecoder().decode(Favorite.self, from: data)
    }
    
    static func deleteFavorite(userId:Int, postId:Int) async throws {
        let endpoint = "\(Env.BASE_URL)\(PATH_TO_CUSTOM_DELETE_FAVORITE_ENDPOINT)"
        let params = "\(USER_PARAM)=\(userId)&\(POST_PARAM)=\(postId)"
        let url = "\(endpoint)?\(params)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterFavoriteErrors(data: data, response: response)
    }
    
    static func deleteFavorite(favorite_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_FAVORITES)\(favorite_id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterFavoriteErrors(data: data, response: response)
    }
}
