//
//  MistboxCountdownManager.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import Foundation

enum MistboxManagerError: Error, Equatable {
    
    case NoMistbox
}

class MistboxManager: NSObject {
    
    //MARK: - Properties
    
    static var shared = MistboxManager()
    static let DAILY_SWIPES = 5
    static let MAX_KEYWORDS = 10
    
    private var mistbox: Mistbox?
    
    var hasUserActivatedMistbox: Bool {
        return mistbox != nil
    }
    
    //MARK: - Initializer
    
    private override init() {
        super.init()
        startTimerToTenAM()
    }
    
    func createMistox(withKeywords keywords: [String]) {
        mistbox = Mistbox(posts: [], keywords: keywords, creation_time: Date().timeIntervalSince1970, opens_used_today: 0)
    }
    
    //MARK: - Setup
    
    var previousHour = Calendar.current.component(.hour, from: Date())
    
    func startTimerToTenAM() {
        Task {
            while true {
                let hasTheClockStruckTen = Calendar.current.component(.hour, from: Date()) == 10 && previousHour == 9
                if hasTheClockStruckTen {
                    try await fetchSyncedMistbox()
                }
                previousHour = Calendar.current.component(.hour, from: Date())
                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 5)
            }
        }
    }
    
    //MARK: - Fetchers
    
    func fetchSyncedMistbox() async throws {
        mistbox = try await PostAPI.fetchMistbox()
        if let mistbox = mistbox {
            let _ = await PostService.singleton.cachePostsAndGetArrayOfPostIdsFrom(posts: mistbox.posts)
        }
    }
    
    //MARK: - Getters
    
    func getRemainingOpens() -> Int? {
        guard let mistbox = mistbox else { return nil }
        return MistboxManager.DAILY_SWIPES - mistbox.opens_used_today
    }
    
    func getCurrentKeywords() -> [String] {
        return mistbox?.keywords ?? []
    }
    
    func getMistboxMists() -> [Post] {
        guard let mistbox = mistbox else { return [] }
        return mistbox.posts
    }
    
    //MARK: - Doeres
    
    func openMist(index: Int, postId: Int) throws {
        guard mistbox != nil else { throw MistboxManagerError.NoMistbox }
        mistbox?.posts.remove(at: index)
        
        Task {
            do {
                try await PostAPI.deleteMistboxPost(post: postId)
                mistbox!.opens_used_today += 1
            } catch {
                print(error)
                throw error
            }
        }
    }
    
    func skipMist(index: Int, postId: Int) throws {
        guard mistbox != nil else { throw MistboxManagerError.NoMistbox }
        mistbox?.posts.remove(at: index)
        
        Task {
            do {
                try await PostAPI.deleteMistboxPost(post: postId)
            } catch {
                print(error)
                throw error
            }
        }
    }
    
    func updateKeywords(to newKeywords: [String]) {
        if mistbox == nil {
            guard newKeywords.count > 0 else {
                return
            }
            createMistox(withKeywords: newKeywords)
        }
        
        mistbox?.keywords = newKeywords
        Task {
            do {
                try await UserService.singleton.updateKeywords(to: newKeywords)
            } catch {
                CustomSwiftMessages.displayError(error)
            }
        }
    }
    
}
