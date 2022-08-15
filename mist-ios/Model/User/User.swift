//
//  User.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation
import MessageKit

//MARK: - Protocols

protocol ReadOnlyUserBackendProperties: Equatable {
    var id: Int { get }
    var username: String { get }
    var first_name: String { get }
    var last_name: String { get }
    var picture: String? { get }
}

protocol CompleteUserBackendProperties: Equatable {
    var id: Int { get }
    var username: String { get }
    var first_name: String { get }
    var last_name: String { get }
    var picture: String? { get }
    var email: String { get }
    var date_of_birth: String { get }
    var sex: String? { get }
    //let phone_number: String?
}

//MARK: - Structs

struct ReadOnlyUser: Codable, ReadOnlyUserBackendProperties, Hashable {
    let id: Int
    let username: String
    let first_name: String
    let last_name: String
    let picture: String?
    
    //Equatable
    static func == (lhs: ReadOnlyUser, rhs: ReadOnlyUser) -> Bool { return lhs.id == rhs.id }
}

// Does not need to be codable, because we're not encoding other user information onto one's device
struct FrontendReadOnlyUser: ReadOnlyUserBackendProperties, SenderType, Hashable {

    // ReadOnlyUserBackendProperties
    let id: Int
    let username: String
    let first_name: String
    let last_name: String
    let picture: String?

    // Frontend-only properties
    var full_name: String {
        return first_name + " " + last_name
    }
    let profilePic: UIImage
    let blurredPic: UIImage
    
    //MessageKit's SenderType
    var senderId: String { return String(id) }
    var displayName: String { return first_name }
    
    init(readOnlyUser: ReadOnlyUser, profilePic: UIImage, blurredPic: UIImage? = nil) {
        self.id = readOnlyUser.id
        self.username = readOnlyUser.username
        self.first_name = readOnlyUser.first_name
        self.last_name = readOnlyUser.last_name
        self.picture = readOnlyUser.picture
        
        self.profilePic = profilePic
        self.blurredPic = blurredPic == nil ? profilePic.blur() : blurredPic!
    }
    
    //Equatable
    static func == (lhs: FrontendReadOnlyUser, rhs: FrontendReadOnlyUser) -> Bool { return lhs.id == rhs.id }
}

struct CompleteUser: Codable, CompleteUserBackendProperties {
    
    let id: Int
    let username: String
    let first_name: String
    let last_name: String
    let picture: String?
    let email: String
    let date_of_birth: String
    let sex: String?
    let latitude: Double?
    let longitude: Double?
    
    //Equatable
    static func == (lhs: CompleteUser, rhs: CompleteUser) -> Bool { return lhs.id == rhs.id }
}

struct FrontendCompleteUser: Codable, CompleteUserBackendProperties, SenderType {
    
    // CompleteUserBackendProperties
    let id: Int
    var username: String
    var first_name: String
    var last_name: String
    var picture: String?
    var email: String
    let date_of_birth: String
    let sex: String?
    let latitude: Double?
    let longitude: Double?
    
    var full_name: String {
        return first_name + " " + last_name
    }
    
    // Frontend-only properties
    var profilePicWrapper: ProfilePicWrapper
    var token: String
    var age: Int? {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let birthday = dateFormatter.date(from: date_of_birth) else { return nil }
            let ageAsElapsedTime = Date().timeIntervalSince1970.getElapsedTime(since: birthday.timeIntervalSince1970)
            return ageAsElapsedTime.years
        }
    }
    
    //MessageKit's SenderType
    var senderId: String { return String(id) }
    var displayName: String { return first_name }
    
    init(completeUser: CompleteUser, profilePic: ProfilePicWrapper, token: String) {
        self.id = completeUser.id
        self.username = completeUser.username
        self.first_name = completeUser.first_name
        self.last_name = completeUser.last_name
        self.picture = completeUser.picture
        self.email = completeUser.email
        self.date_of_birth = completeUser.date_of_birth
        self.sex = completeUser.sex
        self.latitude = completeUser.latitude
        self.longitude = completeUser.longitude
        
        self.profilePicWrapper = profilePic
        self.token = token
    }
    
    //Equatable
    static func == (lhs: FrontendCompleteUser, rhs: FrontendCompleteUser) -> Bool { return lhs.id == rhs.id }
}
