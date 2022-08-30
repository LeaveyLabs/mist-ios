//
//  DeviceAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 8/19/22.
//

import Foundation

fileprivate var DEVICETOKEN = ""

func setGlobalDeviceToken(token:String) {
    DEVICETOKEN = token
}

func getGlobalDeviceToken() -> String {
    return DEVICETOKEN
}

struct DeviceParams: Codable {
    let user: Int
    let registration_id: String
}

struct DeviceErrors: Codable {
    let user: [String]?
    let registration_id: [String]?
    // Errors
    let non_field_errors: [String]?
    let detail: String?
}

class DeviceAPI {
    // MARK: Endpoints
    static let PATH_TO_DEVICES = "api/devices/"
    static let DEVICE_RECOVERY_MESSAGE = "Please try again."
    
    static func filterDeviceErrors(data: Data, response: HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(DeviceErrors.self, from: data)
            
            if let userErrors = error.user,
               let userError = userErrors.first {
                throw APIError.ClientError(userError, DEVICE_RECOVERY_MESSAGE)
            }
            
            if let idErrors = error.registration_id,
               let idError = idErrors.first {
                throw APIError.ClientError(idError, DEVICE_RECOVERY_MESSAGE)
            }
            
        }
        throw APIError.Unknown
    }
    
    static func registerCurrentDeviceWithUser(user:Int) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_DEVICES)"
        let params = DeviceParams(user: user, registration_id: DEVICETOKEN)
        let json = try JSONEncoder().encode(params)
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterDeviceErrors(data: data, response: response)
    }
}
