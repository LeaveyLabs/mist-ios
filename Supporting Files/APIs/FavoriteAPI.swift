//
//  FavoriteAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

class FavoriteAPI {
    static let PATH_TO_FAVORITES = "api/favorites/"
    static let PATH_TO_CUSTOM_DELETE_FAVORITE_ENDPOINT = "api/delete-favorite/"
    static let POST_PARAM = "post"
    static let USER_PARAM = "favoriting_user"
    
    static func fetchFavoritesByUser(userId: Int) async throws -> [Favorite] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FAVORITES)?\(USER_PARAM)=\(userId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Favorite].self, from: data)
    }
    
    static func postFavorite(userId: Int, postId: Int) async throws -> Favorite {
        let url = "\(Env.BASE_URL)\(PATH_TO_FAVORITES)"
        let params = [
            POST_PARAM: postId,
            USER_PARAM: userId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(Favorite.self, from: data)
    }
    
    static func deleteFavorite(userId:Int, postId:Int) async throws {
        let endpoint = "\(Env.BASE_URL)\(PATH_TO_CUSTOM_DELETE_FAVORITE_ENDPOINT)"
        let params = "\(USER_PARAM)=\(userId)&\(POST_PARAM)=\(postId)"
        let url = "\(endpoint)?\(params)"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
    
    static func deleteFavorite(favorite_id:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_FAVORITES)\(favorite_id)/"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
}
