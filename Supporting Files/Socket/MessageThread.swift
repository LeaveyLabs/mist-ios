//
//  MessageThread.swift
//  mist-ios
//
//  Created by Kevin Sun on 5/13/22.
//

import Foundation
import Starscream

class MessageThread {
    var from_user: String;
    var to_user: String;
    var message_queue: [Message];
    var socket: WebSocket;
    
    init(from_user:String, to_user:String) throws {
        self.from_user = from_user;
        self.to_user = to_user;
        self.message_queue = []
        
        let params:[String:String] = ["type": "init",
                                      "from_user":self.from_user,
                                      "to_user":self.to_user]
        let json = try JSONEncoder().encode(params)
        var request = URLRequest(url: URL(string: "http://localhost:8081")!)
        request.httpBody = json
        request.timeoutInterval = 5
        
        self.socket = WebSocket(request: request)
        self.socket.connect()
        self.socket.onEvent = { event in
            switch event {
                case .connected(let headers):
                    print("websocket is connected: \(headers)")
                case .disconnected(let reason, let code):
                    print("websocket is disconnected: \(reason) with code: \(code)")
                case .text(let string):
                    print("Received text: \(string)")
                case .binary(let data):
                    print("Received data: \(data.count)")
                    do {
                        let new_message = try JSONDecoder().decode(Message.self, from: data)
                        self.message_queue.append(new_message)
                    } catch {
                        print("Invalid message format")
                    }
                case .ping(_):
                    break
                case .pong(_):
                    break
                case .viabilityChanged(_):
                    break
                case .reconnectSuggested(_):
                    break
                case .cancelled:
                    break
                case .error(let error):
                    break
                }
        }
    }
    
    deinit {
        self.socket.disconnect()
    }
    
    func sendMessage(message_text:String) throws {
        let params:[String:String] = ["type": "message",
                                      "from_user":self.from_user,
                                      "to_user":self.to_user,
                                      "text": message_text]
        let json = try JSONEncoder().encode(params)
        self.socket.write(data: json)
    }
}
