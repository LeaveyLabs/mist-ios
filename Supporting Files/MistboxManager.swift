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
    static let DAILY_OPENS = 5
    static let MAX_KEYWORDS = 10
    
    private var mistbox: Mistbox?
    
    var hasUserActivatedMistbox: Bool {
        return mistbox != nil
    }
    
    //MARK: - Initializer
    
    private override init() {
        super.init()
        startTimerToTenAM()
        startOccasionalRefreshTask()
    }
    
    func reset() {
        mistbox = nil
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
    
    func startOccasionalRefreshTask() {
        Task {
            while true {
                try await fetchSyncedMistbox()
                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 15)
            }
        }
    }
    
    //MARK: - Fetchers
    
    func fetchSyncedMistbox() async throws {
        guard let newMistbox = try await PostAPI.fetchMistbox() else { return }
        let _ = await PostService.singleton.cachePostsAndGetArrayOfPostIdsFrom(posts: newMistbox.posts)
        print("FETCHED NEW MISTBOX")
        if newMistbox.posts.count > (mistbox?.posts.count ?? 0),
           let tabBarVC = await UIApplication.shared.windows.first?.rootViewController as? SpecialTabBarController,
           await tabBarVC.selectedIndex != 2 {
            DispatchQueue.main.async {
                tabBarVC.refreshBadgeCount()
            }
        }
        mistbox = newMistbox
    }
    
    //MARK: - Getters
    
    func getRemainingOpens() -> Int? {
        guard let mistbox = mistbox else { return nil }
        return MistboxManager.DAILY_OPENS - mistbox.opens_used_today
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
                try await PostAPI.deleteMistboxPost(post: postId, opened: true)
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
                try await PostAPI.deleteMistboxPost(post: postId, opened: false)
            } catch {
                print(error)
                throw error
            }
        }
    }
    
    func updateKeywords(to newKeywords: [String]) async throws {
        if mistbox == nil {
            guard newKeywords.count > 0 else {
                return
            }
            createMistox(withKeywords: newKeywords)
        }
        
        mistbox?.keywords = newKeywords
        try await UserService.singleton.updateKeywords(to: newKeywords)
    }
    
}
