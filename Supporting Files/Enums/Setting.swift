//
//  Setting.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

enum Setting {
    //links
    case merch, instagram
    //settings
    case account, notifications
        case phoneNumber, deleteAccount, logout
    //other
    case shareFeedback
        case rateMist, feedbackForm, leaveReview, contactUs
    case learnMore
        case faq, contentGuidelines, privacyPolicy, terms
    case inHouseFaq
        case howDoesMistWork, mistableMoments, whenAmIAnonymous
    
    var displayName : String {
        switch self {
//        case .email:
//            return "Email".lowercased()
        case .phoneNumber:
            return "Phone Number".lowercased()
        case .contentGuidelines:
            return "Content Guidelines".lowercased()
        case .rateMist:
            return "Rate Mist".lowercased()
        case .faq:
            return "Site FAQ".lowercased()
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
        case .feedbackForm:
            return "Mist feedback form".lowercased()
        case .account:
            return "Account".lowercased()
            return "Collectibles".lowercased()
        case .howDoesMistWork:
            return "How does Mist work?".lowercased()
        case .whenAmIAnonymous:
            return "When am I anonymous?".lowercased()
        case .mistableMoments:
            return "What's a mistable moment?".lowercased()
        case .inHouseFaq:
            return "FAQ".lowercased()
        case .logout:
            return "Logout".lowercased()
        case .merch:
            return "Merch".lowercased()
        case .instagram:
            return "Instagram".lowercased()
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
        case .feedbackForm:
            return UIImage(systemName: "doc.text")!
        case .account:
            return UIImage(systemName: "person.crop.circle")!
        case .notifications:
            return UIImage(systemName: "bell.badge")!
        case .howDoesMistWork:
            return UIImage(systemName: "questionmark.circle")!
        case .mistableMoments:
            return UIImage(systemName: "camera")!
        case .whenAmIAnonymous:
            return UIImage(systemName: "person.fill.questionmark")!
        case .inHouseFaq:
            return UIImage(systemName: "questionmark.circle")!
        case .logout:
            return UIImage(systemName: "arrow.uturn.left.square")!
        case .merch:
            return UIImage(systemName: "tshirt")!
        case .instagram:
            return UIImage(systemName: "camera")!
        }
    }
    
    func tapAction(with settingsTapDelegate: SettingsTapDelegate) {
        switch self {
//        case .email:
//            break
        case .phoneNumber:
            break
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
        case .feedbackForm:
            settingsTapDelegate.handleLink(setting: self)
        case .account:
            settingsTapDelegate.handleAccount(setting: self)
        case .notifications:
            break
        case .howDoesMistWork:
            settingsTapDelegate.handlePresentFaq(setting: self)
        case .mistableMoments:
            settingsTapDelegate.handlePresentFaq(setting: self)
        case .whenAmIAnonymous:
            settingsTapDelegate.handlePresentFaq(setting: self)
        case .inHouseFaq:
            settingsTapDelegate.handleInHouseFaq(setting: self)
        case .logout:
            settingsTapDelegate.handleLogout()
        case .merch:
            settingsTapDelegate.handleLink(setting: self)
        case .instagram:
            settingsTapDelegate.handleLink(setting: self)
        }
    }
}
