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

struct TokenStruct: Codable {
    let token:String;
}

enum AuthError: Error {
    case invalidCredentials
}

class AuthAPI {
    // Registers email in the database
    // (and database will send verifcation email)
    static func registerEmail(email:String) async throws {
        let url = "https://mist-backend.herokuapp.com/api-register/"
        let obj:[String:String] = ["email":email]
        let json = try JSONEncoder().encode(obj)
        let _ = try await BasicAPI.post(url:url, jsonData:json)
    }
    
    // Validates email
    static func validateEmail(email:String, code:String) async throws {
        let url = "https://mist-backend.herokuapp.com/api-validate/"
        let obj:[String:String] = [
            "email": email,
            "code": code
        ]
        let json = try JSONEncoder().encode(obj)
        let (data, response) = try await BasicAPI.post(url:url, jsonData:json)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AuthError.invalidCredentials
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
        let json = try JSONEncoder().encode(user)
        let (data, response) = try await BasicAPI.post(url:url, jsonData:json)
        guard (response as? HTTPURLResponse)?.statusCode == 201 else {
            throw AuthError.invalidCredentials
        }
        return try JSONDecoder().decode(AuthedUser.self, from: data)
    }
    
    static func fetchAuthToken(username:String, password:String) async throws -> String {
        let url = "https://mist-backend.herokuapp.com/api-token/"
        let obj:[String:String] = [
            "username": username,
            "password": password,
        ]
        let json = try JSONEncoder().encode(obj)
        let (data, response) = try await BasicAPI.basicHTTPCallWithoutToken(url:url, jsonData:json, method: "POST")
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AuthError.invalidCredentials
        }
        let tokenStruct = try JSONDecoder().decode(TokenStruct.self, from: data)
        return tokenStruct.token
    }
}
