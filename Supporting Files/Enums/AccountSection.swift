//
//  AccountSection.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

enum AccountSection: Int, CaseIterable {
    case links, settings, other
    
    var displayName : String {
        switch self {
        case .links:
            return "LINKS"
        case .settings:
            return "SETTINGS"
        case .other:
            return "OTHER"
        }
    }
    
    var settings: [Setting] {
        switch self {
        case .links:
            return [.merch, .instagram]
        case .settings:
            return [.account]
        case .other:
            return [.inHouseFaq, .shareFeedback, .learnMore]
        }
    }
}
