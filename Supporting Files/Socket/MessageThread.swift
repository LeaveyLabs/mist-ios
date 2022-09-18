//
//  MessageThread.swift
//  mist-ios
//
//  Created by Kevin Sun on 5/13/22.
//

import Foundation
import Starscream

class MessageThread: WebSocketDelegate {
    
    let sender: Int!
    let receiver: Int!
    let request: URLRequest
    var unsent_messages: [String];
    var server_messages: [Message] {
        didSet {
            ConversationService.singleton.handleMessageThreadSizeIncrease(with: receiver)
        }
    }
    let init_data: Data!
    var socket: WebSocket!
    var connected: Bool = false;
    var connection_in_progress: Bool = true;
    
    init(sender: Int, receiver: Int, previousMessages: [Message]) throws {
        self.sender = sender
        self.receiver = receiver
        self.unsent_messages = []
        self.server_messages = previousMessages.sorted()
        
        let conversationStarter = ConversationStarter(type: "init",
                                                      sender: self.sender,
                                                      receiver: self.receiver)
        let json = try JSONEncoder().encode(conversationStarter)
        self.init_data = json
        
        self.request = URLRequest(url: URL(string: Env.CHAT_URL)!)
        self.connect()
    }
    
    func connect() {
        self.connection_in_progress = true
        self.socket = WebSocket(request: self.request)
        self.socket.delegate = self
        self.socket.connect()
    }
    
    func refreshSocketStatus() {
        guard socket != nil, connected else { return }
        socket.write(ping: Data())
    }
    
    deinit {
        self.socket.disconnect()
    }
    
    func sendMessage(message_text:String) throws {
        // If we're connected, then send it
        if (connected) {
            let messageIntermediate = MessageIntermediate(type: "message",
                                                          sender: self.sender,
                                                          receiver: self.receiver,
                                                          body: message_text,
                                                          token: getGlobalAuthToken())
            let json = try JSONEncoder().encode(messageIntermediate)
            self.socket.write(data:json)
        }
        // Otherwise, put it on the queue of unsent messages
        else {
            unsent_messages.append(message_text)
            if (!connection_in_progress) {
                connect()
            }
        }
    }
    
    func clearUnsentMessages() {
        for unsent_message in unsent_messages {
            let messageIntermediate = MessageIntermediate(type: "message",
                                                          sender: self.sender,
                                                          receiver: self.receiver,
                                                          body: unsent_message,
                                                          token: getGlobalAuthToken())
            do {
                let json = try JSONEncoder().encode(messageIntermediate)
                self.socket.write(data:json)
            } catch {
                print("JSON could not parse unsent message.")
            }
        }
    }
    
    func fetchOfflineMessages() async throws {
        let received_messages = try await MessageAPI.fetchMessagesBySenderAndReceiver(sender: self.receiver, receiver: self.sender)
        let sent_messages = try await MessageAPI.fetchMessagesBySenderAndReceiver(sender: self.sender, receiver: self.receiver)
        let offline_messages = (received_messages + sent_messages).sorted()

        let server_message_ids:Set<Int> = Set(server_messages.map { $0.id })
        Task {
            for offline_message in offline_messages {
                if !server_message_ids.contains(offline_message.id) {
                    self.server_messages.append(offline_message)
                    try await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
                }
            }
        }
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
            case .connected(let headers):
                print("websocket is connected: \(headers)")
                self.connected = true
                self.connection_in_progress = false
                self.socket.write(data: init_data)
                Task {
//                    try await fetchOfflineMessages()
                    clearUnsentMessages()
                }
            case .disconnected(let reason, let code):
                self.connected = false
                self.connection_in_progress = false
                Task {
                    while(!self.connected) {
                        self.connection_in_progress = true
                        connect()
                        self.connection_in_progress = false
                        sleep(5)
                    }
                }
                print("websocket is disconnected: \(reason) with code: \(code)")
            case .text(let string):
                print("Received text: \(string)")
                Task {
                    do {
                        let new_message = try JSONDecoder().decode(Message.self, from: string.data(using: .utf8)!)
                        self.server_messages.append(new_message)
                    } catch {}
                }
            case .binary(let data):
                print("Received data: \(data.count)")
                Task {
                    do {
                        let new_message = try JSONDecoder().decode(Message.self, from: data)
                        self.server_messages.append(new_message)
                    } catch {}
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
                self.connected = false
                self.connection_in_progress = false
                print(error!)
                break
        }
    }
}
