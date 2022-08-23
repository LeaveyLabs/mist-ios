//
//  Setting.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

enum Setting {
    //friends
    case friends
    //mists
    case mentions, submissions, favorites
    //other
    case settings, shareFeedback, learnMore
        case email, phoneNumber, deleteAccount
        case rateMist, leaveReview, contactUs
        case faq, contentGuidelines, privacyPolicy, terms
    
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
        case .contentGuidelines:
            return "Content Guidelines"
        case .friends:
            return "Friends"
        case .rateMist:
            return "Rate Mist"
        case .faq:
            return "FAQ"
        case .contactUs:
            return "Contact us"
        case .deleteAccount:
            return "Delete Account"
        case .privacyPolicy:
            return "Privacy Policy"
        case .terms:
            return "Terms of Use"
        case .settings:
            return "Settings"
        case .shareFeedback:
            return "Share your feedback"
        case .learnMore:
            return "Learn more"
        case .leaveReview:
            return "Leave a review"
        }
    }
    
    var iconImage: UIImage {
        switch self {
        case .email:
            return UIImage(systemName: "envelope")!
        case .phoneNumber:
            return UIImage(systemName: "phone")!
        case .leaveReview:
            return UIImage(systemName: "message")!
        case .friends:
            return UIImage(systemName: "person.2")!
        case .submissions:
            return UIImage(systemName: "plus")!
        case .mentions:
            return UIImage(systemName: "at")!
        case .favorites:
            return UIImage(systemName: "bookmark")!
//        case .notifications:
//            return UIImage(systemName: "bell.badge")!
//        case .shareMist:
//            return UIImage(systemName: "square.and.arrow.up")!
        case .contentGuidelines:
            return UIImage(systemName: "pencil.and.outline")!
        case .shareFeedback:
            return UIImage(systemName: "hand.wave")!
        case .learnMore:
            return UIImage(systemName: "doc.plaintext")!
        case .faq:
            return UIImage(systemName: "questionmark.circle")!
        case .contactUs:
            return UIImage(systemName: "envelope")!
        case .deleteAccount:
            return UIImage(systemName: "person.crop.circle.badge.xmark")!
        case .privacyPolicy:
            return UIImage(systemName: "doc.plaintext")!
        case .terms:
            return UIImage(systemName: "doc.plaintext")!
        case .settings:
            return UIImage(systemName: "gearshape")!
        case .rateMist:
            return UIImage(systemName: "star")!
        }
    }
    
    func tapAction(with settingsTapDelegate: SettingsTapDelegate) {
        switch self {
        case .friends:
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
            settingsTapDelegate.handlePhoneNumber()
//        case .notifications:
//            break
//        case .shareMist:
//            settingsTapDelegate.handleShare()
        case .contentGuidelines:
            settingsTapDelegate.handleLink(setting: self)
        case .shareFeedback:
            settingsTapDelegate.handleShareFeedback()
        case .learnMore:
            settingsTapDelegate.handleLearnMore()
        case .faq:
            settingsTapDelegate.handleLink(setting: self)
        case .contactUs:
            settingsTapDelegate.handleLink(setting: self)
        case .deleteAccount:
            settingsTapDelegate.handleDeleteAccount()
        case .privacyPolicy:
            settingsTapDelegate.handleLink(setting: self)
        case .terms:
            settingsTapDelegate.handleLink(setting: self)
        case .settings:
            settingsTapDelegate.handleSettings()
        case .rateMist:
            AppStoreReviewManager.requestReviewIfAppropriate()
        case .leaveReview:
            settingsTapDelegate.handleLeaveReview()
        }
    }
}
