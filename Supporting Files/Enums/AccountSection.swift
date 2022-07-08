//
//  AccountSection.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

enum AccountSection: Int, CaseIterable {
    case profile, posts, settings, more, logout // friends
    
    var displayName : String {
        switch self {
        case .profile:
            return "PROFILE"
        case .posts:
            return "MISTS"
        case .settings:
            return "SETTINGS"
        case .more:
            return "MORE"
        case .logout:
            return ""
        }
    }
    
    var settings: [Setting] {
        switch self {
        case .profile:
            return []
        case .posts:
            return [.favorites, .submissions]
        case .settings:
            return [.email, .password]
        case .more:
            return [.shareMist, .contentGuidelines, .help, .legal]
        case .logout:
            return []
        }
    }
}
