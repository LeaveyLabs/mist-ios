//
//  BlockService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

class BlockService: NSObject {
    
    static var singleton = BlockService()
    
    private var usersWhoBlockedYou: [Block] = []
    private var usersWhoYouBlocked: [Block] = []

    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    //MARK: - Load
    
    func loadBlocks() async throws {
        async let loadedUsersWhoBlockedYou = BlockAPI.fetchBlocksByBlockedUser(blockedUserId: UserService.singleton.getId())
        async let loadedUsersWhoYouBlocked = BlockAPI.fetchBlocksByBlockingUser(blockingUserId: UserService.singleton.getId())
        (usersWhoBlockedYou, usersWhoYouBlocked) = try await (loadedUsersWhoBlockedYou, loadedUsersWhoYouBlocked)
    }
    
    //MARK: - Getters
    
    func isBlockedBy(_ userId: Int) -> Bool {
        return usersWhoBlockedYou.contains { $0.blocked_user == userId }
    }
    
    func hasBlocked(_ userId: Int) -> Bool {
        return usersWhoYouBlocked.contains { $0.blocked_user == userId }
    }
    
    func isBlockedByOrHasBlocked(_ userId: Int) -> Bool {
        return isBlockedBy(userId) || hasBlocked(userId)
    }
    
    //MARK: - Updaters
    
    func blockUser(_ userToBeBlockedId: Int) throws {
        let newBlock = Block(id: Int.random(in: 0..<Int.max), blocked_user: userToBeBlockedId, blocking_user: UserService.singleton.getId(), timestamp: Date().timeIntervalSince1970)
        usersWhoYouBlocked.append(newBlock)
        Task {
            do {
                let _ = try await BlockAPI.postBlock(blockingUserId: UserService.singleton.getId(), blockedUserId: userToBeBlockedId)
            } catch {
                usersWhoYouBlocked.removeAll { $0.id == newBlock.id }
                throw(error)
            }
        }
    }
    
    func unBlockUser(_ userToBeUnBlockedId: Int) throws {
        let blockToDelete = usersWhoYouBlocked.first { $0.blocked_user == userToBeUnBlockedId }!
        usersWhoYouBlocked.removeAll { $0.id == blockToDelete.id }
        
        Task {
            do {
                let _ = try await BlockAPI.deleteBlock(blockingUserId: UserService.singleton.getId(), blockedUserId: userToBeUnBlockedId)
            } catch {
                usersWhoYouBlocked.append(blockToDelete)
                throw(error)
            }
        }
    }
    
}
