//
//  SettingsTapDelegate.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

protocol SettingsTapDelegate {
    //push new vc
    func handlePosts(setting: Setting)
    func handleLearnMore()
    func handleShareFeedback()
    func handleSettings()
    //other
    func handleDeleteAccount()
    func handleLeaveReview()
    func handleLink(setting: Setting)
    func handlePhoneNumber()
}

extension SettingsTapDelegate where Self: UIViewController {
    
    //MARK: - Push VC
    
    func handlePosts(setting: Setting) {
        guard let customExplore = CustomExploreViewController.create(setting: setting) else { return }
        navigationController?.pushViewController(customExplore, animated: true)
    }
    
    func handleSettings() {
        let settingsVC = SettingsViewController.create(settings: [.email, .phoneNumber, .deleteAccount])
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    func handleShareFeedback() {
        let settingsVC = SettingsViewController.create(settings: [.rateMist, .leaveReview, .contactUs])
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    func handleLearnMore() {
        let settingsVC = SettingsViewController.create(settings: [.faq, .contentGuidelines, .terms, .privacyPolicy])
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
        }
    }
    
    func handleDeleteAccount() {
        CustomSwiftMessages.showAlert(title: "Are you sure you want to delete your account?",
                                      body: "All of your data will be erased, and you will not be able to access or recover it again.",
                                      emoji: "😟", dismissText: "Nevermind", approveText: "Delete",
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
    
    func handlePhoneNumber() {
        let requestPasswordVC = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.RequestResetPassword)
        let navigationController = UINavigationController(rootViewController: requestPasswordVC)
        if view.frame.size.width < 350 { //otherwise the content gets clipped
            navigationController.modalPresentationStyle = .fullScreen
        }
        present(navigationController, animated: true)
    }
    
    //Deprecated
    
//    func handleShare() {
//        presentMistShareActivity()
//    }
    
    //    func handlePassword() {
    //        let passwordSettingVC = PasswordSettingViewController.create()
    //        navigationController?.pushViewController(passwordSettingVC, animated: true)
    //    }

}
