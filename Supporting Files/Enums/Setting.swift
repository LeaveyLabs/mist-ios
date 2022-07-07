//
//  Setting.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

enum Setting {
    case addFriends, myFriends
    case submissions, mentions, favorites
    case email, phoneNumber, password, notifications, explore
    case shareMist, contentGuidelines, help, legal, rateMist, faq
    
    //other screens
    case contactUs, deleteAccount
    case privacyPolicy, termsOfService
    
    var displayName : String {
        switch self {
        case .submissions:
            return "Submissions"
        case .mentions:
            return "Mentions"
        case .favorites:
            return "Favorites"
        case .email:
            return "Email"
        case .phoneNumber:
            return "Phone Number"
        case .password:
            return "Password"
        case .shareMist:
            return "Share Mist"
        case .contentGuidelines:
            return "Content Guidelines"
        case .help:
            return "Help"
        case .legal:
            return "Legal"
        case .addFriends:
            return "Add Friends"
        case .myFriends:
            return "My Friends"
        case .notifications:
            return "Notifications"
        case .explore:
            return "Explore"
        case .rateMist:
            return "Rate Mist"
        case .faq:
            return "FAQ"
        case .contactUs:
            return "Contact Us"
        case .deleteAccount:
            return "Delete Account"
        case .privacyPolicy:
            return "Privacy Policy"
        case .termsOfService:
            return "Terms of Service"
        }
    }
    
    var iconImage: UIImage {
        switch self {
        case .email:
            return UIImage(systemName: "envelope")!
        case .phoneNumber:
            return UIImage(systemName: "phone")!
        case .password:
            return UIImage(systemName: "lock")!
        case .rateMist:
            return UIImage(systemName: "star")!
        case .addFriends:
            return UIImage(systemName: "person.badge.plus")!
        case .myFriends:
            return UIImage(systemName: "person.2")!
        case .submissions:
            return UIImage(systemName: "plus")!
        case .mentions:
            return UIImage(systemName: "at")!
        case .favorites:
            return UIImage(systemName: "bookmark")!
        case .notifications:
            return UIImage(systemName: "bell.badge")!
        case .explore:
            return UIImage(systemName: "magnifyingglass")!
        case .shareMist:
            return UIImage(systemName: "square.and.arrow.up")!
        case .contentGuidelines:
            return UIImage(systemName: "pencil.and.outline")!
        case .help:
            return UIImage(systemName: "hand.wave")!
        case .legal:
            return UIImage(systemName: "doc.plaintext")!
        case .faq:
            return UIImage(systemName: "questionmark.circle")!
        case .contactUs:
            return UIImage(systemName: "message")!
        case .deleteAccount:
            return UIImage(systemName: "person.crop.circle.badge.xmark")!
        case .privacyPolicy:
            return UIImage(systemName: "doc.plaintext")!
        case .termsOfService:
            return UIImage(systemName: "doc.plaintext")!
        }
    }
    
    func tapAction(with settingsTapDelegate: SettingsTapDelegate) {
        switch self {
        case .addFriends:
            break
        case .myFriends:
            break
        case .submissions:
            settingsTapDelegate.handlePosts(setting: self)
        case .mentions:
            settingsTapDelegate.handlePosts(setting: self)
        case .favorites:
            settingsTapDelegate.handlePosts(setting: self)
        case .email:
            break
        case .phoneNumber:
            break
        case .password:
            settingsTapDelegate.handlePassword()
        case .notifications:
            break
        case .explore:
            break
        case .shareMist:
            settingsTapDelegate.handleShare()
        case .contentGuidelines:
            settingsTapDelegate.handleLink(setting: self)
        case .help:
            settingsTapDelegate.handleHelp()
        case .legal:
            settingsTapDelegate.handleLegal()
        case .rateMist:
            break
        case .faq:
            break
        case .contactUs:
            settingsTapDelegate.handleLink(setting: self)
        case .deleteAccount:
            settingsTapDelegate.handleDeleteAccount()
        case .privacyPolicy:
            settingsTapDelegate.handleLink(setting: self)
        case .termsOfService:
            settingsTapDelegate.handleLink(setting: self)
        }
    }
}
