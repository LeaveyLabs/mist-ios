//
//  MessageAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 6/21/22.
//

import Foundation

class MessageAPI {
    static let PATH_TO_BLOCK_MODEL = "api/messages/"
    static let SENDER_PARAM = "sender"
    static let RECEIVER_PARAM = "receiver"
    
    static func fetchMessagesBySenderAndReceiver(sender:Int, receiver:Int) async throws -> [Message] {
        let url = "\(BASE_URL)\(PATH_TO_BLOCK_MODEL)?\(SENDER_PARAM)=\(sender)&\(RECEIVER_PARAM)=\(receiver)"
        let (data, _) = try await BasicAPI.baiscHTTPCallWithToken(url: url, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        return try JSONDecoder().decode([Message].self, from: data)
    }
}
