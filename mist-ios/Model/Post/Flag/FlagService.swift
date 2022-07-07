//
//  FlagService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

class FlagService: NSObject {
    
    static var singleton = FlagService()
    
    private var flagsFromYou: [Flag] = []
    private var flagsOnYou: [Flag] = []

    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    //MARK: - Load
    
    func loadFlags() async throws {
        async let loadedFlags = FlagAPI.fetchFlagsByFlagger(flaggerId: UserService.singleton.getId())
        (flagsFromYou) = try await (loadedFlags)
    }
    
    //MARK: - Getters
    
    func hasFlaggedPost(_ postId: Int) -> Bool {
        return flagsFromYou.contains { $0.post == postId }
    }
    
    //MARK: - Updaters
    
    // Intermediate layer
    func handleFlagUpdate(postId: Int, _ isAdding: Bool) throws {
        if isAdding {
            try flagPost(postId)
        } else {
            try unFlagPost(postId)
        }
    }
    
    private func flagPost(_ postToBeFlagged: Int) throws {
        let newFlag = Flag(id: Int.random(in: 0..<Int.max), flagger: UserService.singleton.getId(), post: postToBeFlagged, timestamp: Date().timeIntervalSince1970, rating: 0)
        flagsFromYou.append(newFlag)
        Task {
            do {
                let _ = try await FlagAPI.postFlag(flaggerId: UserService.singleton.getId(), postId: postToBeFlagged)
            } catch {
                flagsFromYou.removeAll { $0.id == newFlag.id }
                throw(error)
            }
        }
    }
    
    private func unFlagPost(_ postToBeUnFlagged: Int) throws {
        let flagToDelete = flagsFromYou.first { $0.post == postToBeUnFlagged }!
        flagsFromYou.removeAll { $0.id == flagToDelete.id }
        
        Task {
            do {
                let _ = try await FlagAPI.deleteFlag(flaggerId: UserService.singleton.getId(), postId: postToBeUnFlagged)
            } catch {
                flagsFromYou.append(flagToDelete)
                throw(error)
            }
        }
    }
    
}
