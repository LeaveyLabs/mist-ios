//
//  Profile.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/14/22.
//

import Foundation

struct Profile: Codable {
    var username: String;
    var first_name: String;
    var last_name: String;
    var picture: String?;
    let user: Int;
}
