//
//  AuthAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation

class AuthAPI {
    // Registers email in the database
    // (and database will send verifcation email)
    static func registerEmail(email:String) async throws {
        let url = "https://mist-backend.herokuapp.com/api/api-register/"
        let obj:[String:String] = ["email":email]
        let json = try JSONEncoder().encode(obj)
        try await BasicAPI.post(url:url, jsonData:json)
    }
    
    // Validates email
    static func validateEmail(email:String, code:String) async throws {
        let url = "https://mist-backend.herokuapp.com/api/api-validate/"
        let obj:[String:String] = [
            "email": email,
            "code": code
        ]
        let json = try JSONEncoder().encode(obj)
        try await BasicAPI.post(url:url, jsonData:json)
    }
    
    // Creates validated user in the database
    static func createUser(email:String, username:String,
                           password:String, first_name:String,
                           last_name:String) async throws {
        let url = "https://mist-backend.herokuapp.com/api/api-create-user/"
        let obj:[String:String] = [
            "email": email,
            "username": username,
            "password": password,
            "first_name": first_name,
            "last_name": last_name,
        ]
        let json = try JSONEncoder().encode(obj)
        try await BasicAPI.post(url:url, jsonData:json)
    }
}
