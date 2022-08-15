//
//  UserAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation
import UIKit
import Alamofire

extension NSMutableData {
  func appendString(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}

//https://github.com/kean/Nuke

struct UserError: Codable {
    let email: [String]?
    let username: [String]?
    let password: [String]?
    let first_name: [String]?
    let last_name: [String]?
    let date_of_birth: [String]?
    let sex: [String]?
    let latitude: [String]?
    let longitude: [String]?
    
    let non_field_errors: [String]?
    let detail: String?
}

class UserAPI {
    static let PATH_TO_USER_MODEL = "api/users/"
    static let PATH_TO_MATCHES = "api/matches/"
    static let PATH_TO_FRIENDSHIPS = "api/friendships/"
    static let PATH_TO_NEARBY_USERS = "api/nearby-users/"
    static let EMAIL_PARAM = "email"
    static let USERNAME_PARAM = "username"
    static let PASSWORD_PARAM = "password"
    static let FIRST_NAME_PARAM = "first_name"
    static let LAST_NAME_PARAM = "last_name"
    static let DATE_OF_BIRTH_PARAM = "date_of_birth"
    static let SEX_PARAM = "sex"
    static let WORDS_PARAM = "words"
    static let PHONE_NUMBERS_PARAM = "phone_numbers"
    static let TOKEN_PARAM = "token"
    static let LATITUDE_PARAM = "latitude"
    static let LONGITUDE_PARAM = "longitude"
    
    static let USER_RECOVERY_MESSAGE = "Please try again."
    
    static func throwAPIError(error: UserError) throws {
        if let emailErrors = error.email,
            let emailError = emailErrors.first {
            throw APIError.ClientError(emailError, USER_RECOVERY_MESSAGE)
        }
        if let usernameErrors = error.username,
            let usernameError = usernameErrors.first {
            throw APIError.ClientError(usernameError, USER_RECOVERY_MESSAGE)
        }
        if let passwordErrors = error.password,
            let passwordError = passwordErrors.first {
            throw APIError.ClientError(passwordError, USER_RECOVERY_MESSAGE)
        }
        if let firstNameErrors = error.first_name,
           let firstNameError = firstNameErrors.first {
            throw APIError.ClientError(firstNameError, USER_RECOVERY_MESSAGE)
        }
        if let lastNameErrors = error.last_name,
           let lastNameError = lastNameErrors.first {
            throw APIError.ClientError(lastNameError, USER_RECOVERY_MESSAGE)
        }
        if let dobErrors = error.date_of_birth,
           let dobError = dobErrors.first {
            throw APIError.ClientError(dobError, USER_RECOVERY_MESSAGE)
        }
        if let sexErrors = error.sex,
           let sexError = sexErrors.first {
            throw APIError.ClientError(sexError, USER_RECOVERY_MESSAGE)
        }
        if let latitudeErrors = error.latitude,
           let latitudeError = latitudeErrors.first{
            throw APIError.ClientError(latitudeError, USER_RECOVERY_MESSAGE)
        }
        if let longitudeErrors = error.longitude,
           let longitudeError = longitudeErrors.first{
            throw APIError.ClientError(longitudeError, USER_RECOVERY_MESSAGE)
        }
    }
    
    static func filterUserErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(UserError.self, from: data)
            try throwAPIError(error: error)
        }
        throw APIError.Unknown
    }
    
    static func fetchNearbyUsers() async throws -> [ReadOnlyUser] {
        let url = "\(Env.BASE_URL)\(PATH_TO_NEARBY_USERS)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchFriends() async throws -> [ReadOnlyUser] {
        let url = "\(Env.BASE_URL)\(PATH_TO_FRIENDSHIPS)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchMatches() async throws -> [ReadOnlyUser] {
        let url = "\(Env.BASE_URL)\(PATH_TO_MATCHES)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchUsersByUserId(userId:Int) async throws -> ReadOnlyUser {
        let url = "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)\(userId)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode(ReadOnlyUser.self, from: data)
    }
    
    static func fetchUsersByUsername(username:String) async throws -> [ReadOnlyUser] {
        let url = "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)?\(USERNAME_PARAM)=\(username)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchUsersByFirstName(firstName:String) async throws -> [ReadOnlyUser] {
        let url = "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)?\(FIRST_NAME_PARAM)=\(firstName)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchUsersByLastName(lastName:String) async throws -> [ReadOnlyUser] {
        let url = "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)?\(LAST_NAME_PARAM)=\(lastName)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchUsersByWords(words:[String]) async throws -> [ReadOnlyUser] {
        var url = "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)?"
        if words.isEmpty {
            return []
        }
        for word in words {
            url += "\(WORDS_PARAM)=\(word)&"
        }
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchUsersByPhoneNumbers(phoneNumbers:[String]) async throws -> [ReadOnlyUser] {
        var url = "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)?"
        if phoneNumbers.isEmpty {
            return []
        }
        for phoneNumber in phoneNumbers {
            url += "\(PHONE_NUMBERS_PARAM)=\(phoneNumber)&"
        }
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode([ReadOnlyUser].self, from: data)
    }
    
    static func fetchAuthedUserByToken(token:String) async throws -> CompleteUser {
        let url = "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)?\(TOKEN_PARAM)=\(token)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterUserErrors(data: data, response: response)
        let queriedUsers = try JSONDecoder().decode([CompleteUser].self, from: data)
        let tokenUser = queriedUsers[0]
        return tokenUser
    }
    
    static func patchProfilePic(image:UIImage, id:Int, username:String) async throws -> CompleteUser {
        let imgData = image.pngData()
        
        let AUTH_HEADERS:HTTPHeaders = [
            "Authorization": "Token \(getGlobalAuthToken())"
        ]
        
        let request = AF.upload(
            multipartFormData:
                { multipartFormData in
                    multipartFormData.append(imgData!, withName: "picture", fileName: "\(username).png", mimeType: "image/png")
                    multipartFormData.append(imgData!, withName: "confirm_picture", fileName: "\(username).png", mimeType: "image/png")
                },
            to: "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)\(id)/",
            method: .patch,
            headers: AUTH_HEADERS
        )
        
        let response = await request.serializingDecodable(UserError.self).response
        
        if let httpData = response.data, let httpResponse = response.response {
            try BasicAPI.filterBasicErrors(data: httpData, response: httpResponse)
            try filterUserErrors(data: httpData, response: httpResponse)
        } else {
            throw APIError.NoResponse
        }
        
        let authedUser = try await request.serializingDecodable(CompleteUser.self).value
        return authedUser
    }
    
    static func patchUsername(username:String, id:Int) async throws -> CompleteUser {
        let url =  "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)\(id)/"
        let params:[String:String] = [USERNAME_PARAM: username]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.PATCH.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode(CompleteUser.self, from: data)
    }
    
    static func patchPassword(password:String, id:Int) async throws -> CompleteUser {
        let url =  "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)\(id)/"
        let params:[String:String] = [PASSWORD_PARAM: password]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.PATCH.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode(CompleteUser.self, from: data)
    }
    
    static func patchLatitudeLongitude(latitude:Double, longitude:Double, id:Int) async throws -> CompleteUser {
        let url =  "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)\(id)/"
        let params:[String:Double] = [
            LATITUDE_PARAM: latitude,
            LONGITUDE_PARAM: longitude,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.PATCH.rawValue)
        try filterUserErrors(data: data, response: response)
        return try JSONDecoder().decode(CompleteUser.self, from: data)
    }
    
    static func deleteUser(user_id:Int) async throws {
        let url =  "\(Env.BASE_URL)\(PATH_TO_USER_MODEL)\(user_id)/"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        try filterUserErrors(data: data, response: response)
    }
    
    static func UIImageFromURLString(url:String?) async throws -> UIImage {
        guard let url = url else {
            return UIImage(systemName: "person.crop.circle")!
        }

        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterUserErrors(data: data, response: response)
        return UIImage(data: data) ?? UIImage(systemName: "person.crop.circle")!
    }
    
    //MARK: - Batch Calls
    
    static func batchFetchUsersFromUserIds(_ userIds: Set<Int>) async throws -> [Int: ReadOnlyUser] {
      var users: [Int: ReadOnlyUser] = [:]
      try await withThrowingTaskGroup(of: (Int, ReadOnlyUser).self) { group in
        for userId in userIds {
          group.addTask {
              return (userId, try await UserAPI.fetchUsersByUserId(userId: userId))
          }
        }
        // Obtain results from the child tasks, sequentially, in order of completion
        for try await (userId, user) in group {
          users[userId] = user
        }
      }
      return users
    }
    
    static func batchTurnUsersIntoFrontendUsers(_ users: [ReadOnlyUser]) async throws -> [Int: FrontendReadOnlyUser] {
        var frontendUsers: [Int: FrontendReadOnlyUser] = [:]
        try await withThrowingTaskGroup(of: (Int, FrontendReadOnlyUser).self) { group in
          for user in users {
            group.addTask {
                return (user.id, FrontendReadOnlyUser(readOnlyUser: user, profilePic: try await UIImageFromURLString(url: user.picture)))
            }
          }
          // Obtain results from the child tasks, sequentially, in order of completion
          for try await (userId, frontendUser) in group {
            frontendUsers[userId] = frontendUser
          }
        }
        return frontendUsers
    }
    
    static func batchFetchProfilePicsForPicPaths(_ picPaths: [Int: String]) async throws -> [Int: UIImage] {
      var thumbnails: [Int: UIImage] = [:]
      try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
          for (userId, picPath) in picPaths {
              group.addTask {
                  return (userId, try await UserAPI.UIImageFromURLString(url: picPath))
              }
          }
         // Obtain results from the child tasks, sequentially, in order of completion
         for try await (id, thumbnail) in group {
            thumbnails[id] = thumbnail
         }
      }
      return thumbnails
    }
}
