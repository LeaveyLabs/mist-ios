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
        return usersWhoBlockedYou.contains { $0.blocking_user == userId }
    }
    
    func hasBlocked(_ userId: Int) -> Bool {
        return usersWhoYouBlocked.contains { $0.blocked_user == userId }
    }
    
    func isBlockedByOrHasBlocked(_ userId: Int) -> Bool {
        return isBlockedBy(userId) || hasBlocked(userId)
    }
    
    //MARK: - Updaters
    
    func blockUser(_ userToBeBlockedId: Int) async throws {
        let newBlock = Block(id: Int.random(in: 0..<Int.max), blocked_user: userToBeBlockedId, blocking_user: UserService.singleton.getId(), timestamp: Date().timeIntervalSince1970)
        usersWhoYouBlocked.append(newBlock)
        do {
            print("USER TO BE BLOCKED: ", userToBeBlockedId)
            let _ = try await BlockAPI.postBlock(blockingUserId: UserService.singleton.getId(), blockedUserId: userToBeBlockedId)
        } catch {
            usersWhoYouBlocked.removeAll { $0.id == newBlock.id }
            throw(error)
        }
    }
    
    @available(iOS, obsoleted: 4.0, message: "Unblocking is not yet supported")
    func unBlockUser(_ userToBeUnBlockedId: Int) async throws {
        guard let blockToDelete = usersWhoYouBlocked.first(where: { $0.blocked_user == userToBeUnBlockedId }) else { return }
        usersWhoYouBlocked.removeAll { $0.id == blockToDelete.id }
        do {
            let _ = try await BlockAPI.deleteBlock(blockingUserId: UserService.singleton.getId(), blockedUserId: userToBeUnBlockedId)
        } catch {
            usersWhoYouBlocked.append(blockToDelete)
            throw(error)
        }
    }
    
}
