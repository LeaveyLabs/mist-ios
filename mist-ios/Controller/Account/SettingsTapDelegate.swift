//
//  SettingsTapDelegate.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

protocol SettingsTapDelegate: MFMailComposeViewControllerDelegate {
    //push new vc
    func handleProfile()
    func handleAvatar()
    func handlePosts(setting: Setting)
    func handleLearnMore(setting: Setting)
    func handleShareFeedback(setting: Setting)
    func handleAccount(setting: Setting)
    func handleDefaults(setting: Setting)
    func handlePresentFaq(setting: Setting)
    //other
    func handleDeleteAccount()
    func handleLeaveReview()
    func handleLink(setting: Setting)
    func handleCollectibles()
    func handleInHouseFaq(setting: Setting)
}

extension SettingsTapDelegate where Self: UIViewController {
    
    //MARK: - Push VC
    
    func handleProfile() {
        let updateprofileVC = UpdateProfileSettingViewController.create()
        navigationController?.pushViewController(updateprofileVC, animated: true)
    }
    
    func handleAvatar() {
        //do nothing as of now
    }
    
    func handleCollectibles() {
        let collectiblesVC = CollectiblesViewController.create()
        self.navigationController?.pushViewController(collectiblesVC, animated: true)
    }
    
    func handlePosts(setting: Setting) {
        guard let customExplore = CustomExploreParentViewController.create(setting: setting) else { return }
        navigationController?.pushViewController(customExplore, animated: true)
    }
    
    func handlePresentFaq(setting: Setting) {
        switch setting {
        case .howDoesMistWork:
            let vc = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.HowMistWorks) as! HowMistWorksViewController
            present(vc, animated: true)
        case .mistableMoments:
            let vc = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.MistableMoments) as! MistableMomentsViewController
            present(vc, animated: true)
        case .whenAmIAnonymous:
            let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ExplainProfile) as! ExplainProfileViewController
            present(vc, animated: true)
        default:
            return
        }
    }
    
    func handleAccount(setting: Setting) {
        let settingsVC = SettingsViewController.create(settings: [.phoneNumber, .deleteAccount], title: setting.displayName)
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    func handleDefaults(setting: Setting) {
        let settingsVC = DefaultsSettingsViewController.create()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    func handleShareFeedback(setting: Setting) {
        let settingsVC = SettingsViewController.create(settings: [.feedbackForm, .rateMist, .leaveReview, .contactUs], title: setting.displayName)
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    func handleLearnMore(setting: Setting) {
        let settingsVC = SettingsViewController.create(settings: [.faq, .contentGuidelines, .terms, .privacyPolicy], title: setting.displayName)
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    func handleInHouseFaq(setting: Setting) {
        let settingsVC = SettingsViewController.create(settings: [.howDoesMistWork, .whenAmIAnonymous, .mistableMoments], title: setting.displayName)
        navigationController?.pushViewController(settingsVC, animated: true)
    }
        
    func handleLink(setting: Setting) {
        if setting == .privacyPolicy {
            openURL(URL(string: "https://www.getmist.app/privacy-policy")!)
        } else if setting == .terms {
            openURL(URL(string: "https://www.getmist.app/terms-of-use")!)
        } else if setting == .contactUs {
            UIApplication.shared.open(URL(string: "mailto:whatsup@getmist.app")!) //mailto can't use safari
        } else if setting == .contentGuidelines {
            openURL(URL(string: "https://www.getmist.app/content-guidelines")!)
        } else if setting == .faq {
            openURL(URL(string: "https://www.getmist.app/faq")!)
        } else if setting == .feedbackForm {
            openURL(URL(string: "https://forms.gle/FQQpw2hfVqHLb5jU8")!)
        }
    }
    
    func handleDeleteAccount() {
        CustomSwiftMessages.showAlert(title: "are you sure you want to delete your account?",
                                      body: "all of your data will be erased, and you will not be able to access or recover it again",
                                      emoji: "😟", dismissText: "nevermind", approveText: "delete",
                                      onDismiss: {
        }, onApprove: { [self] in
            view.isUserInteractionEnabled = false
            Task {
                try await UserService.singleton.deleteMyAccount()
                setGlobalAuthToken(token: "")
                DispatchQueue.main.async { [self] in
                    transitionToStoryboard(storyboardID: Constants.SBID.SB.Auth,
                                                viewControllerID: Constants.SBID.VC.AuthNavigation,
                                                duration: Env.TRANSITION_TO_HOME_DURATION) { _ in}
                    view.isUserInteractionEnabled = true
                }
            }
        })
    }
    
    func handleLeaveReview() {
        guard let productURL = URL(string: "https://apps.apple.com/app/id1631426995") else { return }
        var components = URLComponents(url: productURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [ URLQueryItem(name: "action", value: "write-review") ]
        guard let writeReviewURL = components?.url else { return }
        UIApplication.shared.open(writeReviewURL)
    }

}

//MARK: - CustomEmailAPpOpener

import MessageUI
import UIKit

extension SettingsTapDelegate where Self: UIViewController {
    
    func sendEmailWithAnyEmailApp(to recipientEmail: String) {
        
        // Show default mail composer
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([recipientEmail])
            
            present(mail, animated: true)
        
        // Show third party email composer if default Mail app is not present
        } else if let emailUrl = createEmailUrl(to: recipientEmail, subject: "", body: "") {
            UIApplication.shared.open(emailUrl)
        }
    }
    
    private func createEmailUrl(to: String, subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let gmailUrl = URL(string: "googlegmail://co?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let outlookUrl = URL(string: "ms-outlook://compose?to=\(to)&subject=\(subjectEncoded)")
        let yahooMail = URL(string: "ymail://mail/compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let sparkUrl = URL(string: "readdle-spark://compose?recipient=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let defaultUrl = URL(string: "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
        
        if let gmailUrl = gmailUrl, UIApplication.shared.canOpenURL(gmailUrl) {
            return gmailUrl
        } else if let outlookUrl = outlookUrl, UIApplication.shared.canOpenURL(outlookUrl) {
            return outlookUrl
        } else if let yahooMail = yahooMail, UIApplication.shared.canOpenURL(yahooMail) {
            return yahooMail
        } else if let sparkUrl = sparkUrl, UIApplication.shared.canOpenURL(sparkUrl) {
            return sparkUrl
        }
        
        return defaultUrl
    }
}
