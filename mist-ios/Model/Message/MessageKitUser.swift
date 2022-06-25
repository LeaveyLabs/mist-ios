//
//  MessageKitUser.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/16.
//


//TODO: delete this struct, it shouldnt be needed anymore. both frontend users now conform to MessageKit's SenderType
//import Foundation
//import MessageKit
//
//struct MessageKitUser: SenderType, Equatable {
//    var senderId: String
//    var displayName: String
//    
//    init(user: FrontendCompleteUser) { //TODO: if Sender can also be the othe person, user shouldnt be frontEndCompleteUser
//        senderId = user.username
//        displayName = user.first_name + " " + user.last_name
//    }
//}
