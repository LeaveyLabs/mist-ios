//
//  CustomTabBarController.swift
//  CustomTabBar
//
//  Created by Adam Novak on 2022-06-07.
//

import UIKit
import Foundation

class SpecialTabBarController: UITabBarController {
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        removeLineAndAddShadow()
        tabBar.applyLightMediumShadow()
        addNotificationsObservers()
        
        
    }
    
    func removeLineAndAddShadow() {
        let tabBarLineHidingView = UIView()
        tabBarLineHidingView.backgroundColor = .white
        tabBar.addSubview(tabBarLineHidingView)
        tabBar.sendSubviewToBack(tabBarLineHidingView)
        tabBarLineHidingView.frame = tabBar.bounds
        tabBarLineHidingView.frame.origin.y -= 1 //hides the tab bar line
        tabBarLineHidingView.frame.size.height += 50 //extends down beyond safe area
    }
}

// MARK: - UITabBarController Delegate

extension SpecialTabBarController: UITabBarControllerDelegate {
    
    func presentNewPostNavVC() {
        let newPostNav = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewPostNavigation)
        newPostNav.modalPresentationStyle = .fullScreen
        present(newPostNav, animated: true, completion: nil)
    }
    
    override func tabBar(_ tabBar: UITabBar, didEndCustomizing items: [UITabBarItem], changed: Bool) {
        presentNewPostNavVC()
    }
}

//MARK: - Notifications

extension SpecialTabBarController {
    
    func setupBadges() {
//        tabBar.items![1].badgeValue = 
//        tabBar.items![2].badgeValue =
    }
    
    var mistboxTabCount: Int {
        Int(tabBar.items![1].badgeValue!)!
    }
    var dmTabCount: Int {
        Int(tabBar.items![2].badgeValue!)!
    }

    func addNotificationsObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNewDMNotificaiton(_:)),
                                               name: .newDM,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNewMentionNotification(_:)),
                                               name: .newMentionedMist,
                                               object: nil)
    }

    @objc func handleNewMentionNotification(_ notification: Notification) {
//        tabBar.items![1].badgeValue = String(mistboxTabCount + 1)
//        tabBar.items![2].badgeValue = String(dmTabCount + 1)
    }
    
    @objc func handleNewDMNotificaiton(_ notification: Notification) {
        tabBar.items![2].badgeValue = String(dmTabCount + 1)
    }
    
}
