//
//  MessageThread.swift
//  mist-ios
//
//  Created by Kevin Sun on 5/13/22.
//

import Foundation
import Starscream

class MessageThread: WebSocketDelegate {
    
    var from_user: String;
    var to_user: String;
    var unsent_messages: [String];
    var server_messages: [Message];
    var init_data: Data;
    var socket: WebSocket;
    var connected: Bool;
    
    init(from_user: String, to_user: String) throws {
        self.from_user = from_user
        self.to_user = to_user
        self.unsent_messages = []
        self.server_messages = []
        self.connected = false
        
        let params:[String:String] = ["type": "init",
                                      "from_user": self.from_user,
                                      "to_user": self.to_user]
        let json = try JSONEncoder().encode(params)
        self.init_data = json
        
        let request = URLRequest(url: URL(string: "ws://localhost:8001/")!)
        self.socket = WebSocket(request: request)
        self.socket.delegate = self
        self.socket.connect()
    }
    
    deinit {
        self.socket.disconnect()
    }
    
    func sendMessage(message_text:String) throws {
        // If we're connected, then send it
        if (connected) {
            let params:[String:String] = ["type": "message",
                                          "from_user":self.from_user,
                                          "to_user":self.to_user,
                                          "text": message_text]
            let json = try JSONEncoder().encode(params)
            self.socket.write(data:json)
        }
        // Otherwise, put it on the queue of unsent messages
        else {
            unsent_messages.append(message_text)
        }
    }
    
    func clearUnsentMessages() {
        for unsent_message in unsent_messages {
            let params:[String:String] = ["type": "message",
                                          "from_user":self.from_user,
                                          "to_user":self.to_user,
                                          "text": unsent_message]
            do {
                let json = try JSONEncoder().encode(params)
                self.socket.write(data:json)
            } catch {
                print("JSON could not parse unsent message.")
            }
        }
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
            case .connected(let headers):
                print("websocket is connected: \(headers)")
                self.socket.write(data: init_data)
                clearUnsentMessages()
            case .disconnected(let reason, let code):
                print("websocket is disconnected: \(reason) with code: \(code)")
            case .text(let string):
                print("Received text: \(string)")
            case .binary(let data):
                print("Received data: \(data.count)")
                do {
                    let new_message = try JSONDecoder().decode(Message.self, from: data)
                    self.server_messages.append(new_message)
                } catch {
                    print("Invalid message format received.")
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
                print(error)
                break
        }
    }
}
