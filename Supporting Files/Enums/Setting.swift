//
//  Setting.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

enum Setting {
    //profile
    case myProfile, avatar
    //friends
    case friends
    //mists
    case mentions, submissions, favorites
    //settings
    case account, defaults, notifications
    //other
    case shareFeedback, learnMore
        case phoneNumber, deleteAccount
        case rateMist, feedbackForm, leaveReview, contactUs
        case faq, contentGuidelines, privacyPolicy, terms
    
    var displayName : String {
        switch self {
        case .submissions:
            return "Submissions".lowercased()
        case .mentions:
            return "Mentions".lowercased()
        case .favorites:
            return "Favorites".lowercased()
//        case .email:
//            return "Email".lowercased()
        case .phoneNumber:
            return "Phone Number".lowercased()
        case .contentGuidelines:
            return "Content Guidelines".lowercased()
        case .friends:
            return "Friends".lowercased()
        case .rateMist:
            return "Rate Mist".lowercased()
        case .faq:
            return "FAQ".lowercased()
        case .contactUs:
            return "Email us".lowercased()
        case .deleteAccount:
            return "Delete Account".lowercased()
        case .privacyPolicy:
            return "Privacy Policy".lowercased()
        case .terms:
            return "Terms of Use".lowercased()
        case .shareFeedback:
            return "Share your feedback".lowercased()
        case .learnMore:
            return "Learn more".lowercased()
        case .leaveReview:
            return "Leave a review".lowercased()
        case .myProfile:
            return ""
        case .avatar:
            return ""
        case .feedbackForm:
            return "Mist feedback form".lowercased()
        case .account:
            return "Account".lowercased()
        case .defaults:
            return "Defaults".lowercased()
        case .notifications:
            return "Notifications".lowercased()
        }
    }
    
    var iconImage: UIImage {
        switch self {
//        case .email:
//            return UIImage(systemName: "envelope")!
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
        case .rateMist:
            return UIImage(systemName: "star")!
        case .myProfile:
            return UIImage()
        case .avatar:
            return UIImage()
        case .feedbackForm:
            return UIImage(systemName: "doc.text")!
        case .account:
            return UIImage(systemName: "person.crop.circle")!
        case .defaults:
            return UIImage(systemName: "iphone")!
        case .notifications:
            return UIImage(systemName: "bell.badge")!
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
//        case .email:
//            break
        case .phoneNumber:
            break
//        case .notifications:
//            break
//        case .shareMist:
//            settingsTapDelegate.handleShare()
        case .contentGuidelines:
            settingsTapDelegate.handleLink(setting: self)
        case .shareFeedback:
            settingsTapDelegate.handleShareFeedback(setting: self)
        case .learnMore:
            settingsTapDelegate.handleLearnMore(setting: self)
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
        case .rateMist:
            AppStoreReviewManager.offerViewPromptUponUserRequest()
        case .leaveReview:
            settingsTapDelegate.handleLeaveReview()
        case .myProfile:
            settingsTapDelegate.handleProfile()
        case .avatar:
            settingsTapDelegate.handleAvatar()
        case .feedbackForm:
            settingsTapDelegate.handleLink(setting: self)
        case .account:
            settingsTapDelegate.handleAccount(setting: self)
        case .defaults:
            settingsTapDelegate.handleDefaults(setting: self)
        case .notifications:
            break
        }
    }
}
