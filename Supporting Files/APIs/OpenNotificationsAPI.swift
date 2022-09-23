//
//  NotificationAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 9/22/22.
//

import Foundation

struct OpenNotificationError: Codable {
    let timestamp: [String]?
    let sangdaebang: [String]?
    let type: [String]?
    
    let non_field_errors: [String]?
    let detail: String?
}

struct OpenNotification: Codable {
    let timestamp: Double
    let sangdaebang: Int?
    let type: String
}

class OpenNotificationsAPI {
    static let PATH_TO_OPEN_NOTIFICATIONS = "api/open-notifications/"
    static let NOTIFICATION_RECOVERY_MESSAGE = "Please try again"
    
    static func filterOpenNotificationErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(OpenNotificationError.self, from: data)
            
            if let timestampErrors = error.timestamp,
               let timestampError = timestampErrors.first {
                throw APIError.ClientError(timestampError, NOTIFICATION_RECOVERY_MESSAGE)
            }
            if let sangdaebangErrors = error.sangdaebang,
               let sangdaebangError = sangdaebangErrors.first {
                throw APIError.ClientError(sangdaebangError, NOTIFICATION_RECOVERY_MESSAGE)
            }
            if let typeErrors = error.type,
               let typeError = typeErrors.first {
                throw APIError.ClientError(typeError, NOTIFICATION_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func openNotification(timestamp:Double, sangdaebang:UserID, type:NotificationTypes) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_OPEN_NOTIFICATIONS)"
        let notification = OpenNotification(timestamp: timestamp, sangdaebang: sangdaebang, type: type.rawValue)
        let json = try JSONEncoder().encode(notification)
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterOpenNotificationErrors(data: data, response: response)
    }
    
    static func openNotification(timestamp:Double, type:NotificationTypes) async throws {
        let url = "\(Env.BASE_URL)\(PATH_TO_OPEN_NOTIFICATIONS)"
        let notification = OpenNotification(timestamp: timestamp, sangdaebang: nil, type: type.rawValue)
        let json = try JSONEncoder().encode(notification)
        let (data, response) = try await BasicAPI.basicHTTPCallWithToken(url: url, jsonData: json, method: HTTPMethods.POST.rawValue)
        try filterOpenNotificationErrors(data: data, response: response)
    }
}
