//
//  AuthAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation
import Alamofire
import UIKit

struct StatusObject : Codable {
    let status:String;
}

struct TokenStruct: Codable {
    let token:String;
}

enum Sex: String {
    case Male = "m"
    case Female = "f"
}

class AuthAPI {
    static let PATH_TO_EMAIL_REGISTRATION = "api-register-email/"
    static let PATH_TO_EMAIL_VALIDATION = "api-validate-email/"
    static let PATH_TO_USERNAME_VALIDATION = "api-validate-username/"
    static let PATH_TO_PASSWORD_VALIDATION = "api-validate-password/"
    static let PATH_TO_PASSWORD_RESET_REQUEST = "api-request-reset-password/"
    static let PATH_TO_PASSWORD_RESET_VALIDATION = "api-validate-reset-password/"
    static let PATH_TO_PASSWORD_RESET_FINALIZATION = "api-finalize-reset-password/"
    static let PATH_TO_API_TOKEN = "api-token/"
    static let AUTH_EMAIL_PARAM = "email"
    static let AUTH_CODE_PARAM = "code"
    static let AUTH_USERNAME_PARAM = "username"
    static let AUTH_PASSWORD_PARAM = "password"
    
    // Registers email in the database
    // (and database will send verifcation email)
    static func registerEmail(email:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_EMAIL_REGISTRATION)"
        let obj:[String:String] = [AUTH_EMAIL_PARAM:email]
        let json = try JSONEncoder().encode(obj)
        let (_, _) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
    }
    
    // Validates email
    static func validateEmail(email:String, code:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_EMAIL_VALIDATION)"
        let params:[String:String] = [
            AUTH_EMAIL_PARAM: email,
            AUTH_CODE_PARAM: code
        ]
        let json = try JSONEncoder().encode(params)
        let (_, _) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
    }
    
    // Validates username
    static func validateUsername(username:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_USERNAME_VALIDATION)"
        let params:[String:String] = [AUTH_USERNAME_PARAM: username]
        let json = try JSONEncoder().encode(params)
        let (_, _) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
    }
    
    // Validates password
    static func validatePassword(username:String, password:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_PASSWORD_VALIDATION)"
        let params:[String:String] = [
            AUTH_USERNAME_PARAM: username,
            AUTH_PASSWORD_PARAM: password,
        ]
        let json = try JSONEncoder().encode(params)
        let (_, _) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
    }
    
    // Creates validated user in the database
    static func createUser(username:String,
                           first_name:String,
                           last_name:String,
                           picture:UIImage?,
                           email:String,
                           password:String,
                           dob: String,
                           sex:String?=nil) async throws -> CompleteUser {
        var params:[String:String] = [
            UserAPI.USERNAME_PARAM: username,
            UserAPI.FIRST_NAME_PARAM: first_name,
            UserAPI.LAST_NAME_PARAM: last_name,
            UserAPI.EMAIL_PARAM: email,
            UserAPI.PASSWORD_PARAM: password,
            UserAPI.DATE_OF_BIRTH_PARAM: dob,
        ]
        if let sex = sex {
            params[UserAPI.SEX_PARAM] = sex
        }
        let request = AF.upload(
            multipartFormData:
                { multipartFormData in
                    for (key, value) in params {
                        multipartFormData.append("\(value)".data(using: .utf8)!, withName: key)
                    }
                    if let picture = picture, let pictureData = picture.pngData() {
                        multipartFormData.append(pictureData, withName: "picture", fileName: "\(username).png", mimeType: "image/png")
                        multipartFormData.append(pictureData, withName: "confirm_picture", fileName: "\(username).png", mimeType: "image/png")
                    }
                },
            to: "\(Env.BASE_URL)\(UserAPI.PATH_TO_USER_MODEL)",
            method: .post
        )
        // TODO: get the response codes through .response
        let response = await request.serializingDecodable(CompleteUser.self).response
        
        
        if let httpResponse = response.response {
            let goodRequest = (200...299).contains(httpResponse.statusCode)
            let badRequest = (400...499).contains(httpResponse.statusCode)
            
            if goodRequest {
                return try await request.serializingDecodable(CompleteUser.self).value
            }
            else if badRequest {
                throw APIError.InvalidCredentials
            }
            else {
                throw APIError.Unknown
            }
        } else {
            throw APIError.NoResponse
        }
    }
    
    static func fetchAuthToken(json: Data) async throws -> String {
        let url = "\(Env.BASE_URL)\(PATH_TO_API_TOKEN)"
        let (data, _) = try await BasicAPI.basicHTTPCallWithoutToken(url:url, jsonData:json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(TokenStruct.self, from: data).token
    }
    
    static func fetchAuthToken(username:String, password:String) async throws -> String {
        let url = "\(Env.BASE_URL)\(PATH_TO_API_TOKEN)"
        let params:[String:String] = [
            UserAPI.USERNAME_PARAM: username,
            UserAPI.PASSWORD_PARAM: password,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, _) = try await BasicAPI.basicHTTPCallWithoutToken(url:url, jsonData:json, method: HTTPMethods.POST.rawValue)
        return try JSONDecoder().decode(TokenStruct.self, from: data).token
    }
    
    static func requestResetPassword(email:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_PASSWORD_RESET_REQUEST)"
        let params:[String:String] = [AUTH_EMAIL_PARAM: email]
        let json = try JSONEncoder().encode(params)
        let (_, _) = try await BasicAPI.basicHTTPCallWithoutToken(url:url, jsonData:json, method: HTTPMethods.POST.rawValue)
    }
    
    static func validateResetPassword(email:String, code:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_PASSWORD_RESET_VALIDATION)"
        let params:[String:String] = [
            AUTH_EMAIL_PARAM: email,
            AUTH_CODE_PARAM: code,
        ]
        let json = try JSONEncoder().encode(params)
        let (_, _) = try await BasicAPI.basicHTTPCallWithoutToken(url:url, jsonData:json, method: HTTPMethods.POST.rawValue)
    }
    
    static func finalizeResetPassword(email:String, password:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_PASSWORD_RESET_FINALIZATION)"
        let params:[String:String] = [
            AUTH_EMAIL_PARAM: email,
            AUTH_PASSWORD_PARAM: password,
        ]
        let json = try JSONEncoder().encode(params)
        let (_, _) = try await BasicAPI.basicHTTPCallWithoutToken(url:url, jsonData:json, method: HTTPMethods.POST.rawValue)
    }
}
