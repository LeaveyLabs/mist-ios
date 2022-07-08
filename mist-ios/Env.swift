//
//  Environment.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/8/22.
//

import Foundation

class Env {
    
    //can you change the logo from here?
    
    #if DEBUG
    static let version: String = "debug"
    static let LAUNCH_ANIMATION_DELAY: Double = 0
    static let LAUNCH_ANIMATION_DURATION: Double = 0
    static let BASE_URL: String = "https://mist-backend-test.herokuapp.com/"
    #else
    static let version: String = "release"
    static let LAUNCH_ANIMATION_DELAY: Double = 1.2
    static let LAUNCH_ANIMATION_DURATION: Double = 0.7
    static let BASE_URL: String = "https://mist-backend-test.herokuapp.com/"
    #endif
    
}

//an alternative
//static var BASE_URL: String = ProcessInfo.processInfo.environment["BASE_URL"]!
