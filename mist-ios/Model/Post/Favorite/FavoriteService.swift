//
//  FavoriteService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

class FavoriteService: NSObject {
    
    static var singleton = FavoriteService()
    
    private var favorites: [Favorite] = [] {
        didSet {
            PostService.singleton.setFavoritePostIds(postIds: favorites.map { $0.post })
        }
    }

    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    //MARK: - Load
    
    func loadFavorites() async throws {
        favorites = try await FavoriteAPI.fetchFavoritesByUser(userId: UserService.singleton.getId())
        try await PostService.singleton.loadFavorites(favoritedPostIds: favorites.map { $0.post } )
    }
    
    //MARK: - Getters
    
    func hasFavoritedPost(_ postId: Int) -> Bool {
        return favorites.contains { $0.post == postId }
    }
    
    //MARK: - Updaters
    
    // Intermediate layer
    func handleFavoriteUpdate(postId: Int, _ isAdding: Bool) throws {
        if isAdding {
            try handleFavoriteAdd(postId: postId)
        } else {
            try handleFavoriteDelete(postId: postId)
        }
    }
    
    private func handleFavoriteAdd(postId: Int) throws {
        let newFavorite = Favorite(id: Int.random(in: 0..<Int.max),
                                              timestamp: Date().timeIntervalSince1970,
                                              post: postId,
                                              favoriting_user: UserService.singleton.getId())
        favorites.append(newFavorite)
        
        Task {
            do {
                let _ = try await FavoriteAPI.postFavorite(userId: UserService.singleton.getId(), postId: postId)
            } catch {
                favorites.removeAll { $0.id == newFavorite.id }
                throw(error)
            }
        }
    }
    
    private func handleFavoriteDelete(postId: Int) throws {
        guard let favoriteToDelete = favorites.first(where: { $0.post == postId }) else { return }
        favorites.removeAll { $0.id == favoriteToDelete.id }
        
        Task {
            do {
                try await FavoriteAPI.deleteFavorite(userId: UserService.singleton.getId(), postId: postId)
            } catch {
                favorites.append(favoriteToDelete)
                throw(error)
            }
        }
    }
    
}
