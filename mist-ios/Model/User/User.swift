//
//  User.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation
import MessageKit

//MARK: - Protocols

protocol ReadOnlyUserType {
    var id: Int { get }
    var username: String { get }
    var first_name: String { get }
    var last_name: String { get }
    var picture: String { get }
    var thumbnail: String { get }
    var badges: [String] { get }
    var full_name: String { get }
    var silhouette: UIImage { get }
    var is_verified: Bool { get }
}

extension ReadOnlyUserType {
    var full_name: String {
        return first_name + " " + last_name
    }
    var silhouette: UIImage {
        return ReadOnlyUser.SilhouetteForId(userId: id)
    }
    var is_verified: Bool {
        return false
    }
}

protocol CompleteUserType: ReadOnlyUserType {
    var email: String? { get }
    var date_of_birth: String? { get }
    var sex: String? { get }
    var phone_number: String { get }
    var daily_prompts: [Int] { get }
}

//MARK: - Structs

struct ReadOnlyUser: Codable, ReadOnlyUserType, Hashable {
    
    var badges: [String]
    let id: Int
    let username: String
    let first_name: String
    let last_name: String
    let picture: String
    let thumbnail: String
    
    static func SilhouetteForId(userId: Int) -> UIImage {
        return UIImage(named: "silhouette" + String([1,2,3,4,5,6][userId % 6]))!
    }
    static func RandomSilhouette() -> UIImage {
        return UIImage(named: "silhouette" + String([1,2,3,4,5,6][Int.random(in: 0..<6)]))!
    }
    
    //Equatable
    static func == (lhs: ReadOnlyUser, rhs: ReadOnlyUser) -> Bool { return lhs.id == rhs.id }
    //Hashable
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// Does not need to be codable, because we're not encoding other user information onto one's device
struct ThumbnailReadOnlyUser: ReadOnlyUserType, SenderType, Hashable {
    
    // ReadOnlyUserBackendProperties
    let id: Int
    let username: String
    let first_name: String
    let last_name: String
    let picture: String
    let thumbnail: String
    var badges: [String]
    
    // Frontend-only properties
    var profilePic: UIImage? //not loaded in unless clicked on a profile
    let thumbnailPic: UIImage //loaded in immediately. exists on every FrontendReadOnlyUser
    
    //MessageKit's SenderType
    var senderId: String { return String(id) }
    var displayName: String { return first_name }
    
    init(readOnlyUser: ReadOnlyUser, thumbnailPic: UIImage, profilePic: UIImage? = nil) {
        self.id = readOnlyUser.id
        self.username = readOnlyUser.username
        self.first_name = readOnlyUser.first_name
        self.last_name = readOnlyUser.last_name
        self.picture = readOnlyUser.picture
        self.badges = readOnlyUser.badges
        self.thumbnail = readOnlyUser.thumbnail
        
        self.thumbnailPic = thumbnailPic
        self.profilePic = profilePic
        
    }
    
    //Equatable
    static func == (lhs: ThumbnailReadOnlyUser, rhs: ThumbnailReadOnlyUser) -> Bool { return lhs.id == rhs.id }
    //Hashable
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct CompleteUser: Codable, CompleteUserType {
    
    let id: Int
    let username: String
    let first_name: String
    let last_name: String
    let picture: String
    var thumbnail: String
    let email: String?
    let date_of_birth: String?
    let sex: String?
    let latitude: Double?
    let longitude: Double?
    let phone_number: String
    let badges: [String]
    let is_superuser: Bool
    var daily_prompts: [Int]
    
    //Equatable
    static func == (lhs: CompleteUser, rhs: CompleteUser) -> Bool { return lhs.id == rhs.id }
}

struct FrontendCompleteUser: Codable, CompleteUserType, ReadOnlyUserType, SenderType {
    
    // CompleteUserBackendProperties
    let id: Int
    var username: String
    var first_name: String
    var last_name: String
    var picture: String
    var thumbnail: String
    var email: String?
    let date_of_birth: String?
    let sex: String?
    let latitude: Double?
    let longitude: Double?
    let phone_number: String
    let badges: [String]
    let is_superuser: Bool
    var daily_prompts: [Int]
    
    // Complete-only properties
    var profilePicWrapper: ProfilePicWrapper
    var token: String
    
    //MessageKit's SenderType
    var senderId: String { return String(id) }
    var displayName: String { return first_name }
    
    init(completeUser: CompleteUser, profilePicWrapper: ProfilePicWrapper, token: String) {
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
        self.phone_number = completeUser.phone_number
        self.badges = completeUser.badges
        self.is_superuser = completeUser.is_superuser
        self.profilePicWrapper = profilePicWrapper
        self.thumbnail = completeUser.thumbnail
        self.token = token
        self.daily_prompts = completeUser.daily_prompts
    }
    
    //Equatable
    static func == (lhs: FrontendCompleteUser, rhs: FrontendCompleteUser) -> Bool { return lhs.id == rhs.id }
    
    static let nilUser = FrontendCompleteUser(completeUser: CompleteUser(id: 0, username: "", first_name: "", last_name: "", picture: "", thumbnail: "", email: "", date_of_birth: "", sex: "", latitude: 0, longitude: 0, phone_number: "", badges: [], is_superuser: false, daily_prompts: []), profilePicWrapper: ProfilePicWrapper(image: Constants.defaultProfilePic, withCompresssion: false), token: "")
}

//    var age: Int? {
//        get {
//            let dateFormatter = DateFormatter()
//            dateFormatter.locale = Locale(identifier: "en_US")
//            dateFormatter.dateFormat = "yyyy-MM-dd"
//            guard let birthday = dateFormatter.date(from: date_of_birth) else { return nil }
//            let ageAsElapsedTime = Date().timeIntervalSince1970.getElapsedTime(since: birthday.timeIntervalSince1970)
//            return ageAsElapsedTime.years
//        }
//    }
