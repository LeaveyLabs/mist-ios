//
//  UsersService.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/14/22.
//

import Foundation

class UsersService: NSObject {
    
    static var singleton = UsersService()
    private var cachedUsers: [Int: FrontendReadOnlyUser] = [:]
    
    //ALTERNATIVELY: cachedUsers -> cachedUserTasks as [Int: Task<>]
    //slightly more optimal, because maybe a usertask was almost finished loading when you checked and saw it was empty
    //instead of awaiting loads, we would await accesses.
    //we'd have to await the user EVERYTIME you accessed it
    //not going to use this approach for now

    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
        
    //MARK: - Fetch one
    
    func loadAndCacheUser(userId: Int) async throws -> FrontendReadOnlyUser {
        if let cachedUser = cachedUsers[userId] {
            return cachedUser
        }
        
        let fetchedBackendUser = try await UserAPI.fetchUsersByUserId(userId: userId)
        let fetchedUser = try await UserAPI.turnUserIntoFrontendUser(fetchedBackendUser)
        cachedUsers[userId] = fetchedUser
        return fetchedUser
    }
    
    //TODO: return optional users
    //right now, 404 errors of "user not found" for a certain ID are just propagated as errors. this is probably better handled as returning an optional user
    //do the following check:
//    let nserror = error as NSError
//    if nserror.code != 404 {
//    }
    
    func loadAndCacheUser(phoneNumber: String) async throws -> FrontendReadOnlyUser {
        fatalError("need to implement load for phone number")
        let fetchedBackendUser = try await UserAPI.fetchUsersByUserId(userId: Int(phoneNumber)!)
        
        if let cachedUser = cachedUsers[fetchedBackendUser.id] {
            return cachedUser
        }
        
        let fetchedUser = try await UserAPI.turnUserIntoFrontendUser(fetchedBackendUser)
        cachedUsers[fetchedUser.id] = fetchedUser
        return fetchedUser
    }
        
    func loadAndCacheUser(user: ReadOnlyUser) async throws -> FrontendReadOnlyUser {
        if let cachedUser = cachedUsers[user.id] {
            return cachedUser
        }
        
        let fetchedUser = try await UserAPI.turnUserIntoFrontendUser(user)
        cachedUsers[user.id] = fetchedUser
        return fetchedUser
    }
    
    //MARK: Fetch several

    func loadAndCacheUsers(userIds: [Int]) async throws -> [Int: FrontendReadOnlyUser] {
        var noncachedUserIds = [Int]()
        var alreadyCachedUsers = [Int: FrontendReadOnlyUser]()
        for userId in userIds {
            if let cachedUser = cachedUsers[userId] {
                alreadyCachedUsers[userId] = cachedUser
            } else {
                noncachedUserIds.append(userId)
            }
        }
        
        //Only fetch and cache the users we haven't already cached
        let users = try await UserAPI.batchFetchUsersFromUserIds(Set(noncachedUserIds))
        let fetchedUsers = try await UserAPI.batchTurnUsersIntoFrontendUsers(users.map { $0.value })
        fetchedUsers.forEach { userId, user in
            cachedUsers[userId] = user
        }
        
        //Return the set intersection
        return fetchedUsers.merging(alreadyCachedUsers) { (old, new) in new }
    }
    
    func loadAndCacheUsers(users: [ReadOnlyUser]) async throws -> [Int: FrontendReadOnlyUser] {
        var noncachedUsers = [ReadOnlyUser]()
        var alreadyCachedUsers = [Int: FrontendReadOnlyUser]()
        for user in users {
            if let cachedUser = cachedUsers[user.id] {
                alreadyCachedUsers[user.id] = cachedUser
            } else {
                noncachedUsers.append(user)
            }
        }
        
        //Only fetch and cache the users we haven't already cached
        let fetchedUsers = try await UserAPI.batchTurnUsersIntoFrontendUsers(noncachedUsers)
        fetchedUsers.forEach { userId, user in
            cachedUsers[userId] = user
        }
        
        //Return the set intersection
        return fetchedUsers.merging(alreadyCachedUsers) { (old, new) in new }
    }
    
    //MARK: - Getters
    
    func isUserCached(userId: Int) -> Bool {
        return cachedUsers[userId] != nil
    }
    
    func getPotentiallyCachedUser(userId: Int) -> FrontendReadOnlyUser? {
        return cachedUsers[userId]
    }
    
}
