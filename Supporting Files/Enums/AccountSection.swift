//
//  AccountSection.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

enum AccountSection: Int, CaseIterable {
    case profile, posts, other, logout //friends
    
    var displayName : String {
        switch self {
        case .profile:
            return "PROFILE"
//        case .friends:
//            return "FRIENDS"
        case .posts:
            return "MISTS"
        case .other:
            return "OTHER"
        case .logout:
            return ""
        }
    }
    
    var settings: [Setting] {
        switch self {
        case .profile:
            return [.myProfile, .avatar]
//        case .friends:
//            return [.friends]
        case .posts:
            return [.mentions, .submissions, .favorites]
        case .other:
            return [.settings, .shareFeedback, .learnMore]
        case .logout:
            return []
        }
    }
}
