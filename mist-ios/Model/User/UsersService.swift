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
    private var cachedUsers: [Int: ThumbnailReadOnlyUser] = [:]
    private var cachedProfilePics: [Int: UIImage] = [:]
    private var usersInContacts: [PhoneNumber: ReadOnlyUser] = [:]
    private var totalNumberOfUsers: Int?
    
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
    
    func loadTotalUserCount() async throws {
        totalNumberOfUsers = try await UserAPI.fetchUserCount()
    }
    
    func loadAndCacheUser(userId: Int) async throws -> ThumbnailReadOnlyUser? {
        if let cachedUser = cachedUsers[userId] {
            return cachedUser
        }
        
        let fetchedBackendUser = try await UserAPI.fetchUserByUserId(userId: userId)
        let fetchedUser = try await UserAPI.turnUserIntoFrontendUser(fetchedBackendUser)
        cachedUsers[userId] = fetchedUser
        return fetchedUser
    }
    
    func loadAndCacheProfilePic(frontendUser: ThumbnailReadOnlyUser) async throws -> UIImage {
        if let profilePic = cachedProfilePics[frontendUser.id] {
            return profilePic
        }
        
        let profilePic = try await UserAPI.UIImageFromURLString(url: frontendUser.picture)
        cachedProfilePics[frontendUser.id] = profilePic
        if cachedUsers[frontendUser.id] != nil {
            cachedUsers[frontendUser.id]?.profilePic = profilePic
        }
        return profilePic
    }
    
    func loadAndCacheUser(phoneNumber: String) async throws -> ThumbnailReadOnlyUser? {
        guard let fetchedBackendUser = try await UserAPI.fetchUsersByPhoneNumbers(phoneNumbers: [phoneNumber]).first?.value else { return nil }
        if let cachedUser = cachedUsers[fetchedBackendUser.id] {
            return cachedUser
        }
        
        let fetchedUser = try await UserAPI.turnUserIntoFrontendUser(fetchedBackendUser)
        cachedUsers[fetchedUser.id] = fetchedUser
        return fetchedUser
    }
        
    func loadAndCacheUser(user: ReadOnlyUser) async throws -> ThumbnailReadOnlyUser {
        if let cachedUser = cachedUsers[user.id] {
            return cachedUser
        }
        
        let fetchedUser = try await UserAPI.turnUserIntoFrontendUser(user)
        cachedUsers[user.id] = fetchedUser
        return fetchedUser
    }
    
    //MARK: Fetch several

    func loadAndCacheEverythingForUsers(userIds: [Int]) async throws -> [Int: ThumbnailReadOnlyUser] {
        var noncachedUserIds = [Int]()
        var alreadyCachedUsers = [Int: ThumbnailReadOnlyUser]()
        for userId in userIds {
            if let cachedUser = cachedUsers[userId] {
                alreadyCachedUsers[userId] = cachedUser
            } else {
                noncachedUserIds.append(userId)
            }
        }
        
        //Only fetch and cache the users we haven't already cached
        let users = try await UserAPI.batchFetchUsersFromUserIds(Set(noncachedUserIds))
        async let frontendUsers = UserAPI.batchTurnUsersIntoFrontendUsers(users.map { $0.value })
        let fetchedUsers  = try await frontendUsers
        fetchedUsers.forEach { userId, user in
            cachedUsers[userId] = user
        }
        
        //Return the set union
        return fetchedUsers.merging(alreadyCachedUsers) { (old, new) in new }
    }
    
    func loadAndCacheProfilePics(users: [ReadOnlyUserType]) async throws -> [Int: UIImage] {
        var noncachedUserIds = [Int]()
        var alreadyCachedPics = [Int: UIImage]()
        for userId in users.map({ $0.id }) {
            if let cachedPic = cachedProfilePics[userId] {
                alreadyCachedPics[userId] = cachedPic
            } else {
                noncachedUserIds.append(userId)
            }
        }
        
        //Only fetch and cache the users we haven't already cached
        let fetchedPics = try await UserAPI.batchFetchProfilePics(users)
        fetchedPics.forEach { userId, pic in
            cachedProfilePics[userId] = pic
        }
        
        //Return the set union
        return fetchedPics.merging(alreadyCachedPics) { (old, new) in new }
    }
    
    func loadAndCacheUsers(phoneNumbers: [PhoneNumber]) async throws -> [PhoneNumber: ThumbnailReadOnlyUser] {
        let usersByPhoneNumber = try await UserAPI.fetchUsersByPhoneNumbers(phoneNumbers: phoneNumbers)
        
        var noncachedUsers = [ReadOnlyUser]()
        var alreadyCachedUsers = [PhoneNumber: ThumbnailReadOnlyUser]()
        for user in usersByPhoneNumber {
            if let cachedUser = cachedUsers[user.value.id] {
                alreadyCachedUsers[user.key] = cachedUser
            } else {
                noncachedUsers.append(user.value)
            }
        }
        
        //Only fetch and cache the users we haven't already cached
        var newlyCachedUsers = [PhoneNumber: ThumbnailReadOnlyUser]()
        let fetchedUsers = try await UserAPI.batchTurnUsersIntoFrontendUsers(noncachedUsers)
        usersByPhoneNumber.forEach { phoneNumber, user in
            if let fetchedUser = fetchedUsers[user.id] { //if we just fetched the profile pic for that particular user
                newlyCachedUsers[phoneNumber] = fetchedUser //then associate the profile pic with their phone number
            }
        }
        
        //Return the set union
        return newlyCachedUsers.merging(alreadyCachedUsers) { (old, new) in new }
    }
    
    func loadAndCacheUsers(users: [ReadOnlyUser]) async throws -> [Int: ThumbnailReadOnlyUser] {
        var noncachedUsers = [ReadOnlyUser]()
        var alreadyCachedUsers = [Int: ThumbnailReadOnlyUser]()
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
            usersInContacts = try await UserAPI.fetchUsersByPhoneNumbers(phoneNumbers: allContacts.compactMap { $0.bestPhoneNumberE164 })
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
    
    func getPotentiallyCachedUser(userId: Int) -> ThumbnailReadOnlyUser? {
        return cachedUsers[userId]
    }
    
    func getPotentiallyCachedProfilePic(userId: Int) -> UIImage? {
        return cachedProfilePics[userId]
    }
    
    func getTotalUsersCount() -> Int? {
        return totalNumberOfUsers
    }
    
    //MARK: - Updaters
    
    func updateCachedUser(updatedUser: ThumbnailReadOnlyUser) {
        cachedUsers[updatedUser.id] = updatedUser
    }
    
}
