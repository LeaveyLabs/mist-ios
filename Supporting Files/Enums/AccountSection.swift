//
//  AccountSection.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

enum AccountSection: Int, CaseIterable {
    case profile, posts, settings, other, logout //friends
    
    var displayName : String {
        switch self {
        case .profile:
            return "PROFILE"
//        case .friends:
//            return "FRIENDS"
        case .posts:
            return "MISTS"
        case .settings:
            return "SETTINGS"
        case .other:
            return "OTHER"
        case .logout:
            return ""
        }
    }
    
    var settings: [Setting] {
        switch self {
        case .profile:
            return [.myProfile, .collectibles]
//        case .friends:
//            return [.friends]
        case .posts:
            return [.mentions, .submissions, .favorites]
        case .settings:
            return [.account, .defaults]
        case .other:
            return [.inHouseFaq, .shareFeedback, .learnMore]
        case .logout:
            return []
        }
    }
}
