//
//  CollectibleManager.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/24/22.
//

import Foundation

class CollectibleManager: NSObject {
    
    //MARK: - Properties
    
    static var shared = CollectibleManager()
        
    var hasUserEarnedACollectibleToday: Bool {
        return earned_collectibles.contains(where: { collectible in
            UserService.singleton.getTodaysPrompts().contains(where: { prompt in
                collectible == prompt
            })
        })
    }
    
    var hasUserEarnedAllCollectibles: Bool {
        return Collectible.COLLECTIBLES_COUNT == earned_collectibles.count
    }
    
    var earned_collectibles: [Int] {
        return PostService.singleton.getSubmissions().compactMap( { $0.collectible_type })
    }
    
    
    //MARK: - Initializer
    
    private override init() {
        super.init()
        startTimerToTenAM()
    }
    
    //MARK: - Setup
    
    var previousHour = Calendar.current.component(.hour, from: Date())
    
    func startTimerToTenAM() {
        Task {
            while true {
                let hasTheClockStruckTen = Calendar.current.component(.hour, from: Date()) == 10 && previousHour == 9
                if hasTheClockStruckTen {
                    try await UserService.singleton.reloadTodaysPrompts()
                }
                previousHour = Calendar.current.component(.hour, from: Date())
                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 5)
            }
        }
    }
}
