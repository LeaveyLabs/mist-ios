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
        //create a vc with the setting
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
            openURL(URL(string: "mailto:whatsup@getmist.app")!)
        } else if setting == .contentGuidelines {
            openURL(URL(string: "https://www.getmist.app/content-guidelines")!)
        }
    }
    
    func handleShare() {
        presentMistShareActivity()
    }
    
    func handleDeleteAccount() {
        //honestly, present a whole ass vc would be ideal... maybe later
        //call back which will delete their account
    }

}
