//
//  AuthAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation
import Alamofire
import UIKit

// Token Format
struct APIToken: Codable {
    let token:String;
}

// Error Formats
struct EmailRegistrationError: Codable {
    let email: [String]?
}

struct EmailValidationError: Codable {
    let email: [String]?
    let code: [String]?
    // Errors
    let non_field_errors: [String]?
    let detail: [String]?
}

struct UsernameValidationError: Codable {
    let username: [String]?
    // Errors
    let non_field_errors: [String]?
    let detail: [String]?
}

struct PasswordValidationError: Codable {
    let username: [String]?
    let password: [String]?
    // Errors
    let non_field_errors: [String]?
    let detail: [String]?
}

struct UserCreationError: Codable {
    let username: [String]?
    let first_name: [String]?
    let last_name: [String]?
    let picture: [String]?
    let email: [String]?
    let password: [String]?
    let dob: [String]?
    let sex: [String]?
    // Errors
    let non_field_errors: [String]?
    let detail: [String]?
}

struct LoginError: Codable {
    let email_or_username: [String]?
    let password: [String]?
    // Errors
    let non_field_errors: [String]?
    let detail: [String]?
}

struct RequestResetPasswordError: Codable {
    let email: [String]?
    // Errors
    let non_field_errors: [String]?
    let detail: [String]?
}

struct ValidateResetPasswordError: Codable {
    let email: [String]?
    let code: [String]?
    // Errors
    let non_field_errors: [String]?
    let detail: [String]?
}

struct FinalizeResetPasswordError: Codable {
    let email: [String]?
    let password: [String]?
    // Errors
    let non_field_errors: [String]?
    let detail: [String]?
}

// Property Enums
enum Sex: String {
    case Male = "m"
    case Female = "f"
    case Other = "o"
}

class AuthAPI {
    // Endpoints
    static let PATH_TO_EMAIL_REGISTRATION = "api-register-email/"
    static let PATH_TO_EMAIL_VALIDATION = "api-validate-email/"
    static let PATH_TO_USERNAME_VALIDATION = "api-validate-username/"
    static let PATH_TO_PASSWORD_VALIDATION = "api-validate-password/"
    static let PATH_TO_PASSWORD_RESET_REQUEST = "api-request-reset-password/"
    static let PATH_TO_PASSWORD_RESET_VALIDATION = "api-validate-reset-password/"
    static let PATH_TO_PASSWORD_RESET_FINALIZATION = "api-finalize-reset-password/"
    static let PATH_TO_API_TOKEN = "api-token/"
    // Parameters
    static let AUTH_EMAIL_PARAM = "email"
    static let AUTH_CODE_PARAM = "code"
    static let AUTH_USERNAME_PARAM = "username"
    static let AUTH_EMAIL_OR_USERNAME_PARAM = "email_or_username"
    static let AUTH_PASSWORD_PARAM = "password"
    // Error Descriptions
    static let LOGIN_ERROR_DESCRIPTION = "Unable to log in"
    // Error Recovery Messages
    static let EMAIL_RECOVERY_MESSAGE = "Please try another email."
    static let CODE_RECOVERY_MESSAGE = "Please try another code."
    static let USERNAME_RECOVERY_MESSAGE = "Please try another username."
    static let FIRST_NAME_RECOVERY_MESSAGE = "Please try another first name."
    static let LAST_NAME_RECOVERY_MESSAGE = "Please try another last name."
    static let PICTURE_RECOVERY_MESSAGE = "Please try another picture."
    static let PASSWORD_RECOVERY_MESSAGE = "Please try another password."
    static let DOB_RECOVERY_MESSAGE = "Please enter a valid date of birth."
    static let SEX_RECOVERY_MESSAGE = "Please try again."
    static let EMAIL_OR_USERNAME_RECOVERY_MESSAGE = "Please try a valid email or username."
    static let USERNAME_PASSWORD_RECOVERY_MESSAGE = "Please enter a valid username or email, and password."
    
    // Registers email in the database
    // (and database will send verifcation email)
    static func registerEmail(email:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_EMAIL_REGISTRATION)"
        let params = [AUTH_EMAIL_PARAM: email]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterEmailRegistrationErrors(data: data, response: response)
    }
    
    static func filterEmailRegistrationErrors(data: Data, response: HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(EmailRegistrationError.self, from: data)
            
            if let emailErrors = error.email,
               let emailError = emailErrors.first {
                throw APIError.ClientError(emailError, EMAIL_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    // Validates email
    static func validateEmail(email:String, code:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_EMAIL_VALIDATION)"
        let params = [
            AUTH_EMAIL_PARAM: email,
            AUTH_CODE_PARAM: code,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterEmailValidationErrors(data: data, response: response)
    }
    
    static func filterEmailValidationErrors(data: Data, response: HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(EmailValidationError.self, from: data)
            
            if let emailErrors = error.email,
               let emailError = emailErrors.first {
                throw APIError.ClientError(emailError, EMAIL_RECOVERY_MESSAGE)
            }
            if let codeErrors = error.code,
               let codeError = codeErrors.first {
                throw APIError.ClientError(codeError, CODE_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    // Validates username
    static func validateUsername(username:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_USERNAME_VALIDATION)"
        let params:[String:String] = [AUTH_USERNAME_PARAM: username]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterUsernameValidationErrors(data: data, response: response)
    }
    
    static func filterUsernameValidationErrors(data: Data, response: HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(UsernameValidationError.self, from: data)
            if let usernameErrors = error.username,
               let usernameError = usernameErrors.first {
                throw APIError.ClientError(usernameError, USERNAME_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
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
    
    static func filterPasswordValidationErrors(data: Data, response: HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(PasswordValidationError.self, from: data)
            if let usernameErrors = error.username,
               let usernameError = usernameErrors.first {
                throw APIError.ClientError(usernameError, USERNAME_RECOVERY_MESSAGE)
            }
            if let passwordErrors = error.password,
               let passwordError = passwordErrors.first {
                throw APIError.ClientError(passwordError, PASSWORD_RECOVERY_MESSAGE)
            }
            if let nonFieldErrors = error.non_field_errors,
                let nonFieldError = nonFieldErrors.first {
                throw APIError.ClientError(nonFieldError, USERNAME_PASSWORD_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
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
        
        let response = await request.serializingDecodable(UserCreationError.self).response
        
        if let httpData = response.data, let httpResponse = response.response {
            try BasicAPI.filterBasicErrors(data: httpData, response: httpResponse)
            try filterUserCreationErrors(data: httpData, response: httpResponse)
        }
        
        return try await request.serializingDecodable(CompleteUser.self).value
    }
    
    static func filterUserCreationErrors(data: Data, response: HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(UserCreationError.self, from: data)
            if let usernameErrors = error.username,
               let usernameError = usernameErrors.first {
                throw APIError.ClientError(usernameError, USERNAME_RECOVERY_MESSAGE)
            }
            if let firstNameErrors = error.first_name,
               let firstNameError = firstNameErrors.first {
                throw APIError.ClientError(firstNameError, FIRST_NAME_RECOVERY_MESSAGE)
            }
            if let lastNameErrors = error.last_name,
               let lastNameError = lastNameErrors.first {
                throw APIError.ClientError(lastNameError, LAST_NAME_RECOVERY_MESSAGE)
            }
            if let pictureErrors = error.picture,
               let pictureError = pictureErrors.first {
                throw APIError.ClientError(pictureError, PICTURE_RECOVERY_MESSAGE)
            }
            if let emailErrors = error.email,
               let emailError = emailErrors.first {
                throw APIError.ClientError(emailError, EMAIL_RECOVERY_MESSAGE)
            }
            if let passwordErrors = error.password,
               let passwordError = passwordErrors.first {
                throw APIError.ClientError(passwordError, PASSWORD_RECOVERY_MESSAGE)
            }
            if let dobErrors = error.dob,
               let dobError = dobErrors.first {
                throw APIError.ClientError(dobError, DOB_RECOVERY_MESSAGE)
            }
            if let sexErrors = error.sex,
               let sexError = sexErrors.first {
                throw APIError.ClientError(sexError, SEX_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func fetchAuthToken(json: Data) async throws -> String {
        let url = "\(Env.BASE_URL)\(PATH_TO_API_TOKEN)"
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url:url, jsonData:json, method: HTTPMethods.POST.rawValue)
        try filterAuthTokenErrors(data: data, response: response)
        return try JSONDecoder().decode(APIToken.self, from: data).token
    }
    
    static func fetchAuthToken(email_or_username:String, password:String) async throws -> String {
        let url = "\(Env.BASE_URL)\(PATH_TO_API_TOKEN)"
        let params:[String:String] = [
            AUTH_EMAIL_OR_USERNAME_PARAM: email_or_username,
            AUTH_PASSWORD_PARAM: password,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url:url, jsonData:json, method: HTTPMethods.POST.rawValue)
        try filterAuthTokenErrors(data: data, response: response)
        return try JSONDecoder().decode(APIToken.self, from: data).token
    }
    
    static func filterAuthTokenErrors(data: Data, response: HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(LoginError.self, from: data)
            if let emailOrUsernameErrors = error.email_or_username,
               let emailOrUsernameError = emailOrUsernameErrors.first {
                throw APIError.ClientError(emailOrUsernameError, EMAIL_OR_USERNAME_RECOVERY_MESSAGE)
            }
            if let passwordErrors = error.password,
               let passwordError = passwordErrors.first {
                throw APIError.ClientError(passwordError, PASSWORD_RECOVERY_MESSAGE)
            }
            if let _ = error.non_field_errors {
                throw APIError.ClientError(LOGIN_ERROR_DESCRIPTION,
                                           USERNAME_PASSWORD_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func requestResetPassword(email:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_PASSWORD_RESET_REQUEST)"
        let params:[String:String] = [AUTH_EMAIL_PARAM: email]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url:url, jsonData:json, method: HTTPMethods.POST.rawValue)
        try filterPasswordResetRequestErrors(data: data, response: response)
    }
    
    static func filterPasswordResetRequestErrors(data: Data, response: HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(RequestResetPasswordError.self, from: data)
            if let emailErrors = error.email,
               let emailError = emailErrors.first {
                throw APIError.ClientError(emailError, EMAIL_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func validateResetPassword(email:String, code:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_PASSWORD_RESET_VALIDATION)"
        let params:[String:String] = [
            AUTH_EMAIL_PARAM: email,
            AUTH_CODE_PARAM: code,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url:url, jsonData:json, method: HTTPMethods.POST.rawValue)
        try filterPasswordResetValidationErrors(data: data, response: response)
    }
    
    static func filterPasswordResetValidationErrors(data: Data, response: HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(ValidateResetPasswordError.self, from: data)
            if let emailErrors = error.email,
               let emailError = emailErrors.first {
                throw APIError.ClientError(emailError, EMAIL_RECOVERY_MESSAGE)
            }
            if let codeErrors = error.code,
               let codeError = codeErrors.first {
                throw APIError.ClientError(codeError, CODE_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func finalizeResetPassword(email:String, password:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_PASSWORD_RESET_FINALIZATION)"
        let params:[String:String] = [
            AUTH_EMAIL_PARAM: email,
            AUTH_PASSWORD_PARAM: password,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url:url, jsonData:json, method: HTTPMethods.POST.rawValue)
        try filterPasswordResetFinalizationErrors(data: data, response: response)
    }
    
    static func filterPasswordResetFinalizationErrors(data: Data, response: HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(FinalizeResetPasswordError.self, from: data)
            if let emailErrors = error.email,
               let emailError = emailErrors.first {
                throw APIError.ClientError(emailError, EMAIL_RECOVERY_MESSAGE)
            }
            if let passwordErrors = error.password,
               let passwordError = passwordErrors.first {
                throw APIError.ClientError(passwordError, PASSWORD_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
}
