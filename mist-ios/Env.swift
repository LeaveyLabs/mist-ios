//
//  Environment.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/8/22.
//

import Foundation

class Env {
        
    enum EnvType: String {
        case prod, dev
    }
    
    #if DEV
    static let environment: EnvType = .dev
    static let LAUNCH_ANIMATION_DELAY: Double = 0
    static let LAUNCH_ANIMATION_DURATION: Double = 0
    static let BASE_URL: String = "https://mist-backend-test.herokuapp.com/"
    static let CHAT_URL: String = "wss://mist-chat-test.herokuapp.com/"
    #elseif DEBUG
    static let environment: EnvType = .dev
    static let LAUNCH_ANIMATION_DELAY: Double = 0
    static let LAUNCH_ANIMATION_DURATION: Double = 0
    static let BASE_URL: String = "https://mist-backend-test.herokuapp.com/"
    static let CHAT_URL: String = "wss://mist-chat-test.herokuapp.com/"
//    #if DEBUG
    //^there's also the option for debug/release flags for more specificity within each environment
    #else
    static let environment: EnvType = .prod
    static let LAUNCH_ANIMATION_DELAY: Double = 1.2
    static let LAUNCH_ANIMATION_DURATION: Double = 0.7
    static let BASE_URL: String = "https://mist-backend.herokuapp.com/"
    static let CHAT_URL: String = "wss://mist-chat.herokuapp.com/"
    #endif
}

// if using the environment dictionary located within scheme management:
//    static let asdf = ProcessInfo.processInfo.environment["BASE_URL"]!

//if using the environment dictionary from a plist file
//    static let env_dict = Bundle.main.infoDictionary!["LSEnvironment"] as! [String: Any]
