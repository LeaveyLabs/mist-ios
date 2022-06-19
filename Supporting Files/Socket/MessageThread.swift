//
//  MessageThread.swift
//  mist-ios
//
//  Created by Kevin Sun on 5/13/22.
//

import Foundation
import Starscream

class MessageThread: WebSocketDelegate {
    
    var sender: Int;
    var receiver: Int;
    var unsent_messages: [String];
    var server_messages: [Message];
    var init_data: Data;
    var socket: WebSocket;
    var connected: Bool;
    
    init(sender: Int, receiver: Int) throws {
        self.sender = sender
        self.receiver = receiver
        self.unsent_messages = []
        self.server_messages = []
        self.connected = false
        
        let params:[String:String] = ["type": "init",
                                      "sender": String(self.sender),
                                      "receiver": String(self.receiver)]
        let json = try JSONEncoder().encode(params)
        self.init_data = json
        
        let request = URLRequest(url: URL(string: "wss://mist-chat-test.herokuapp.com/")!)
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
                                          "sender": String(self.sender),
                                          "receiver": String(self.receiver),
                                          "body": message_text,
                                          "token": getGlobalAuthToken()]
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
                                          "sender": String(self.sender),
                                          "receiver": String(self.receiver),
                                          "body": unsent_message,
                                          "token": getGlobalAuthToken()]
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
                do {
                    let new_message = try JSONDecoder().decode(Message.self, from: string.data(using: .utf8)!)
                    self.server_messages.append(new_message)
                } catch {
                    print("Not a message.")
                }
            case .binary(let data):
                print("Received data: \(data.count)")
                do {
                    let new_message = try JSONDecoder().decode(Message.self, from: data)
                    self.server_messages.append(new_message)
                    print(self.server_messages)
                } catch {
                    print("Not a message.")
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
                print(error!)
                break
        }
    }
}
