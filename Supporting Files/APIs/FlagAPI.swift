//
//  FlagAPI.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation

enum FlagError: Error {
    case badAPIEndPoint
    case badId
}

class FlagAPI {
    // Fetch flags with the postID from database
    static func fetchFlags(postId:String) async throws -> [Flag] {
        return []
    }

    // Post flag to the database
    static func postFlag(flag:Flag) async throws {
        
    }

    // Delete flag (with the id) from database
    static func postFlag(id:String) async throws {
        
    }
}

