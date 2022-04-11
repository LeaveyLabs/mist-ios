//
//  Profile.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation

struct Profile: Codable {
    let username: String;
    let first_name: String;
    let last_name: String;
    let picture: String?;
}
