//
//  PhoneNumberAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 8/13/22.
//

import Foundation

typealias ResetToken = String

struct PhoneNumberError: Codable {
    let email: [String]?
    let phone_number: [String]?
    let code: [String]?
    let token: [String]?
    // Error
    let non_field_errors: [String]?
    let detail: String?
}

class PhoneNumberAPI {
    static let PATH_TO_REGISTER_PHONE_NUMBER = "api-register-phone-number/"
    static let PATH_TO_VALIDATE_PHONE_NUMBER = "api-validate-phone-number/"
    static let PATH_TO_REQUEST_LOGIN_CODE = "api-request-login-code/"
    static let PATH_TO_VALIDATE_LOGIN_CODE = "api-validate-login-code/"
    static let PATH_TO_REQUEST_RESET_EMAIL = "api-request-reset-email/"
    static let PATH_TO_VALIDATE_RESET_EMAIL = "api-validate-reset-email/"
    static let PATH_TO_REQUEST_RESET_TEXT = "api-request-reset-text/"
    static let PATH_TO_VALIDATE_RESET_TEXT = "api-validate-reset-text/"
    
    static let EMAIL_PARAM = "email"
    static let PHONE_NUMBER_PARAM = "phone_number"
    static let CODE_PARAM = "code"
    static let TOKEN_PARAM = "token"
    
    static let PHONE_NUMBER_RECOVERY_MESSAGE = "Please try again"
    
    static func filterPhoneNumberErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(PhoneNumberError.self, from: data)
            
            if let emailErrors = error.email,
               let emailError = emailErrors.first {
                throw APIError.ClientError(emailError, PHONE_NUMBER_RECOVERY_MESSAGE)
            }
            if let phoneNumberErrors = error.phone_number,
               let phoneNumberError = phoneNumberErrors.first {
                throw APIError.ClientError(phoneNumberError, PHONE_NUMBER_RECOVERY_MESSAGE)
            }
            if let codeErrors = error.code,
               let codeError = codeErrors.first {
                throw APIError.ClientError(codeError, PHONE_NUMBER_RECOVERY_MESSAGE)
            }
            if let tokenErrors = error.token,
               let tokenError = tokenErrors.first {
                throw APIError.ClientError(tokenError, PHONE_NUMBER_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func registerNewPhoneNumber(phoneNumber:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_REGISTER_PHONE_NUMBER)"
        let params:[String:String] = [
            PHONE_NUMBER_PARAM: phoneNumber,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterPhoneNumberErrors(data: data, response: response)
    }
    
    static func validateNewPhoneNumber(phoneNumber:String, code:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_VALIDATE_PHONE_NUMBER)"
        let params:[String:String] = [
            PHONE_NUMBER_PARAM: phoneNumber,
            CODE_PARAM: code,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterPhoneNumberErrors(data: data, response: response)
    }
    
    static func requestLoginCode(phoneNumber:String) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_REQUEST_LOGIN_CODE)"
        let params:[String:String] = [
            PHONE_NUMBER_PARAM: phoneNumber,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterPhoneNumberErrors(data: data, response: response)
    }
    
    static func validateLoginCode(phoneNumber:String, code:String) async throws -> String {
        let url = "\(Env.BASE_URL)\(PATH_TO_VALIDATE_LOGIN_CODE)"
        let params:[String:String] = [
            PHONE_NUMBER_PARAM: phoneNumber,
            CODE_PARAM: code,
        ]
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterPhoneNumberErrors(data: data, response: response)
        return try JSONDecoder().decode(APIToken.self, from: data).token
    }
}
