//
//  MessageAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/21/22.
//

import Foundation

typealias UserID = Int

struct MessageError: Codable {
    let sender: [String]?
    let receiver: [String]?
    
    let non_field_errors: [String]?
    let detail: [String]?
}

class MessageAPI {
    static let PATH_TO_MESSAGE_MODEL = "api/messages/"
    static let PATH_TO_CONVERSATIONS = "api/conversations/"
    static let SENDER_PARAM = "sender"
    static let RECEIVER_PARAM = "receiver"
    
    static let MESSAGE_RECOVERY_MESSAGE = "Please try again later"
    
    static func filterMessageErrors(data:Data, response:HTTPURLResponse) throws {
        let statusCode = response.statusCode
        
        if isSuccess(statusCode: statusCode) { return }
        if isClientError(statusCode: statusCode) {
            let error = try JSONDecoder().decode(MessageError.self, from: data)
            
            if let senderErrors = error.sender,
               let senderError = senderErrors.first {
                throw APIError.ClientError(senderError, MESSAGE_RECOVERY_MESSAGE)
            }
            if let receiverErrors = error.receiver,
               let receiverError = receiverErrors.first {
                throw APIError.ClientError(receiverError, MESSAGE_RECOVERY_MESSAGE)
            }
        }
        throw APIError.Unknown
    }
    
    static func fetchMessagesBySender(sender:Int) async throws -> [Message] {
        let url = "\(Env.BASE_URL)\(PATH_TO_MESSAGE_MODEL)?\(SENDER_PARAM)=\(sender)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterMessageErrors(data: data, response: response)
        return try JSONDecoder().decode([Message].self, from: data)
    }
    
    static func fetchMessagesByReceiver(receiver:Int) async throws -> [Message] {
        let url = "\(Env.BASE_URL)\(PATH_TO_MESSAGE_MODEL)?\(RECEIVER_PARAM)=\(receiver)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterMessageErrors(data: data, response: response)
        return try JSONDecoder().decode([Message].self, from: data)
    }
    
    static func fetchMessagesBySenderAndReceiver(sender:Int, receiver:Int) async throws -> [Message] {
        let url = "\(Env.BASE_URL)\(PATH_TO_MESSAGE_MODEL)?\(SENDER_PARAM)=\(sender)&\(RECEIVER_PARAM)=\(receiver)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterMessageErrors(data: data, response: response)
        return try JSONDecoder().decode([Message].self, from: data)
    }
    
    static func fetchConversations() async throws -> [UserID: [Message]] {
        let url = "\(Env.BASE_URL)\(PATH_TO_CONVERSATIONS)"
        let (data, response) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        try filterMessageErrors(data: data, response: response)
        return try JSONDecoder().decode([UserID: [Message]].self, from: data)
    }
}
