//
//  AuthAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation

struct StatusObject : Codable {
    let status:String;
}

class AuthAPI {
    // Registers email in the database
    // (and database will send verifcation email)
    static func registerEmail(email:String) async throws {
        let url = "https://mist-backend.herokuapp.com/api-register/"
        let obj:[String:String] = ["email":email]
        let json = try JSONEncoder().encode(obj)
        _ = try await BasicAPI.post(url:url, jsonData:json)
    }
    
    // Validates email
    static func validateEmail(email:String, code:String) async throws {
        let url = "https://mist-backend.herokuapp.com/api-validate/"
        let obj:[String:String] = [
            "email": email,
            "code": code
        ]
        let json = try JSONEncoder().encode(obj)
        let data = try await BasicAPI.post(url:url, jsonData:json)
        let status = try JSONDecoder().decode(StatusObject.self, from: data)
        if status.status != "success" {
            throw APIError.generic
        }
    }
    
    // Creates validated user in the database
    static func createUser(username:String,
                           first_name:String,
                           last_name:String,
                           picture:String?,
                           email:String,
                           password:String) async throws -> AuthedUser {
        let url = "https://mist-backend.herokuapp.com/api/users/"
        
        let user = AuthedUser(username: username,
                              first_name: first_name,
                              last_name: last_name,
                              picture: picture,
                              email: email,
                              password: password)
        
        //TODO: Delete
//        let obj:[String:String] = [
//            "email": email,
//            "username": username,
//            "password": password,
//            "first_name": first_name,
//            "last_name": last_name,
//        ]
//        let json = try JSONEncoder().encode(obj)
        let json = try JSONEncoder().encode(user)
        let data = try await BasicAPI.post(url:url, jsonData:json)
        return try JSONDecoder().decode(AuthedUser.self, from: data)
    }
}
