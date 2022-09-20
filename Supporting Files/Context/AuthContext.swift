//
//  AuthContext.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/25.
//

import Foundation

struct AuthContext {
    static let APPLE_PHONE_NUMBER: String = "13103103101"
    static let APPLE_CODE: String = "123456"
    
    static var username: String = ""
//    static var email: String = ""
    static var phoneNumber: String = ""
//    static var password: String = "" //depcreated
    static var firstName: String = ""
    static var lastName: String = ""
//    static var dob: String = ""
//    static var sex: String?
    static var accessCode: String? = nil
    
    static var resetToken: ResetToken = ""
    
    static func reset() {
        username = ""
//        email = ""
        phoneNumber = ""
//        password = ""
        firstName = ""
        lastName = ""
//        dob = ""
//        sex = nil
        resetToken = ""
        accessCode = nil
    }
}
