//
//  FavoriteAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/9/22.
//

import Foundation

class FavoriteAPI {
    static let PATH_TO_FAVORITES = "api/favorites/"
    static let POST_PARAM = "post"
    static let USER_PARAM = "favoriting_user"
    
    static func fetchFavoritesByUser(userId: Int) async throws -> [Favorite] {
        let url = "\(BASE_URL)\(PATH_TO_FAVORITES)?\(USER_PARAM)=\(userId)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Favorite].self, from: data)
    }
    
    static func postFavorite(userId: Int, postId: Int) async throws -> Favorite {
        let url = "\(BASE_URL)\(PATH_TO_FAVORITES)"
        let params = [
            POST_PARAM: postId,
            USER_PARAM: userId,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(Favorite.self, from: data)
    }
    
    static func deleteFavorite(userId:Int, postId:Int) async throws {
        let userFavorites = try await FavoriteAPI.fetchFavoritesByUser(userId: userId)
        let favoriteToDelete = userFavorites.first { $0.post == postId }
        guard let favoriteToDelete = favoriteToDelete else {
            throw APIError.NotFound
        }
        let _ = try await FavoriteAPI.deleteFavorite(favorite_id: favoriteToDelete.id)
    }
    
    static func deleteFavorite(favorite_id:Int) async throws {
        let url = "\(BASE_URL)\(PATH_TO_FAVORITES)\(favorite_id)/"
        let (_, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
    }
}