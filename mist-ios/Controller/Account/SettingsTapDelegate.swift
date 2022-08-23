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
    func handleLegal()
    func handleHelp()
    func handlePassword()
    func handleLink(setting: Setting)
    //other
    func handleShare()
    func handleDeleteAccount()
    
}

extension SettingsTapDelegate where Self: UIViewController {
    
    func handlePosts(setting: Setting) {
        guard let customExplore = CustomExploreViewController.create(setting: setting) else { return }
        navigationController?.pushViewController(customExplore, animated: true)
    }
    
    func handleLegal() {
        let settingsVC = SettingsViewController.create(settings: [.privacyPolicy, .terms])
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    func handleHelp() {
        let settingsVC = SettingsViewController.create(settings: [.contactUs, .deleteAccount])
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    func handlePassword() {
        let passwordSettingVC = PasswordSettingViewController.create()
        navigationController?.pushViewController(passwordSettingVC, animated: true)
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
        }
    }
    
    func handleShare() {
        presentMistShareActivity()
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

}
