//
//  CustomTabBarController.swift
//  CustomTabBar
//
//  Created by Adam Novak on 2022-06-07.
//

import UIKit
import Foundation

enum Tabs: Int, CaseIterable {
    case explore, prompts, mistbox, dms
}

class SpecialTabBarController: UITabBarController {
    
//    var promptsTabBadgeCount: Int! {
//        didSet {
//            DispatchQueue.main.async { [self] in
//                tabBar.items![1].badgeValue = promptsTabBadgeCount == 0 ? nil : String(promptsTabBadgeCount)
//                repositionBadges() //necessary or else badge position is incorrect
//            }
//        }
//    }
    
    var mistboxTabBadgeCount: Int! {
        didSet {
            DispatchQueue.main.async { [self] in
                tabBar.items![Tabs.mistbox.rawValue].badgeValue = mistboxTabBadgeCount == 0 ? nil : String(mistboxTabBadgeCount)
                repositionBadges() //necessary or else badge position is incorrect
            }
        }
    }
    
    var dmTabBadgeCount: Int! {
        didSet {
            DispatchQueue.main.async { [self] in
                tabBar.items![Tabs.dms.rawValue].badgeValue = dmTabBadgeCount == 0 ? nil : String(dmTabBadgeCount)
                repositionBadges()
            }
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.items?.forEach({ item in
            item.badgeColor = Constants.Color.mistLilacPurple
            item.setBadgeTextAttributes([NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 12)!], for: .normal)
        })
        removeLineAndAddShadow()
        tabBar.applyLightMediumShadow()
        refreshBadgeCount()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK: - Setup
    
    func removeLineAndAddShadow() {
        let tabBarLineHidingView = UIView()
        tabBarLineHidingView.backgroundColor = .white
        tabBar.addSubview(tabBarLineHidingView)
        tabBar.sendSubviewToBack(tabBarLineHidingView)
        tabBarLineHidingView.frame = tabBar.bounds
        tabBarLineHidingView.frame.origin.y -= 1 //hides the tab bar line
        tabBarLineHidingView.frame.size.height += 50 //extends down beyond safe area
    }
    
    func repositionBadges() {
         tabBar.subviews.forEach({ tab in
             tab.subviews.forEach { badgeView in
                 if NSStringFromClass(badgeView.classForCoder) == "_UIBadgeView" {
                    badgeView.layer.transform = CATransform3DIdentity
                     badgeView.layer.transform = CATransform3DMakeTranslation(-13.0, -1.0, 1.0)
                  }
             }
         })
     }
}

// MARK: - UITabBarController Delegate

extension SpecialTabBarController: UITabBarControllerDelegate {
    
    func presentNewPostNavVC(animated: Bool = true) {
        let newPostNav = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewPostNavigation)
        newPostNav.modalPresentationStyle = .fullScreen
        present(newPostNav, animated: animated, completion: nil)
    }
    
    override func tabBar(_ tabBar: UITabBar, didEndCustomizing items: [UITabBarItem], changed: Bool) {
        presentNewPostNavVC()
    }

}

//MARK: - Notifications

extension SpecialTabBarController {
    
    func decrementMistboxBadgeCount() {
        mistboxTabBadgeCount -= 1
    }
    
    @MainActor
    func refreshBadgeCount() {
        if MistboxManager.shared.hasUserActivatedMistbox {
            mistboxTabBadgeCount = MistboxManager.shared.getMistboxMists().count + DeviceService.shared.unreadMentionsCount()
        } else {
            tabBar.items![Tabs.mistbox.rawValue].badgeValue = ""
            repositionBadges() //necessary or else badge position is incorrect
        }
        
        dmTabBadgeCount = ConversationService.singleton.getUnreadConversations().count
        
        tabBar.items![Tabs.prompts.rawValue].badgeValue = CollectibleManager.shared.hasUserEarnedACollectibleToday ? nil : ""
    }
    
}
