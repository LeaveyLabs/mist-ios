//
//  UsersService.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/14/22.
//

import Foundation
import Contacts

actor UsersService: NSObject {
    
    static var singleton = UsersService()
    private var cachedUsers: [Int: FrontendReadOnlyUser] = [:]
    private var usersInContacts: [PhoneNumber: ReadOnlyUser] = [:]
    
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
    
    func loadAndCacheUser(userId: Int) async throws -> FrontendReadOnlyUser? {
        if let cachedUser = cachedUsers[userId] {
            return cachedUser
        }
        
        let fetchedBackendUser = try await UserAPI.fetchUsersByUserId(userId: userId)
        let fetchedUser = try await UserAPI.turnUserIntoFrontendUser(fetchedBackendUser)
        cachedUsers[userId] = fetchedUser
        return fetchedUser
    }
    
    func loadAndCacheUser(phoneNumber: String) async throws -> FrontendReadOnlyUser? {
        guard let fetchedBackendUser = try await UserAPI.fetchUsersByPhoneNumbers(phoneNumbers: [phoneNumber]).first?.value else { return nil }
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
        
        //Return the set union
        return fetchedUsers.merging(alreadyCachedUsers) { (old, new) in new }
    }
    
    func loadAndCacheUsers(phoneNumbers: [PhoneNumber]) async throws -> [PhoneNumber: FrontendReadOnlyUser] {
        let usersByPhoneNumber = try await UserAPI.fetchUsersByPhoneNumbers(phoneNumbers: phoneNumbers)
        
        var noncachedUsers = [ReadOnlyUser]()
        var alreadyCachedUsers = [PhoneNumber: FrontendReadOnlyUser]()
        for user in usersByPhoneNumber {
            if let cachedUser = cachedUsers[user.value.id] {
                alreadyCachedUsers[user.key] = cachedUser
            } else {
                noncachedUsers.append(user.value)
            }
        }
        
        //Only fetch and cache the users we haven't already cached
        var newlyCachedUsers = [PhoneNumber: FrontendReadOnlyUser]()
        let fetchedUsers = try await UserAPI.batchTurnUsersIntoFrontendUsers(noncachedUsers)
        usersByPhoneNumber.forEach { phoneNumber, user in
            if let fetchedUser = fetchedUsers[user.id] { //if we just fetched the profile pic for that particular user
                newlyCachedUsers[phoneNumber] = fetchedUser //then associate the profile pic with their phone number
            }
        }
        
        //Return the set union
        return newlyCachedUsers.merging(alreadyCachedUsers) { (old, new) in new }
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
        
        //Return the set union
        return fetchedUsers.merging(alreadyCachedUsers) { (old, new) in new }
    }
    
    //MARK: - Idk
        
    func loadUsersAssociatedWithContacts() async {
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else { return }
        let contactStore = CNContactStore()
        var allContacts = [CNContact]()
        let keysToFetch = [CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        do {
            try contactStore.enumerateContacts(with: request) {
                (contact, stop) in
                allContacts.append(contact) // Array containing all unified contacts from everywhere
            }
            print("allContacts mapped", allContacts.compactMap { $0.bestPhoneNumberE164 })
            usersInContacts = try await UserAPI.fetchUsersByPhoneNumbers(phoneNumbers: allContacts.compactMap { $0.bestPhoneNumberE164 })
            print("usersInContacts:", usersInContacts)
        } catch {
            print("Failed to fetch users for contacts, error: \(error)")
        }
    }
    
    //MARK: - Getters
    
    func isUserCached(userId: Int) -> Bool {
        return cachedUsers[userId] != nil
    }
    
    func getUserAssociatedWithContact(phoneNumber: PhoneNumber) -> ReadOnlyUser? {
        return usersInContacts[phoneNumber]
    }
    
    func getPotentiallyCachedUser(userId: Int) -> FrontendReadOnlyUser? {
        return cachedUsers[userId]
    }
    
}
