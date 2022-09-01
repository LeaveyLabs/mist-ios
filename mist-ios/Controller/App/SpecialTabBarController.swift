//
//  CustomTabBarController.swift
//  CustomTabBar
//
//  Created by Adam Novak on 2022-06-07.
//

import UIKit

class SpecialTabBarController: UITabBarController {
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        removeLineAndAddShadow()
        tabBar.applyLightMediumShadow()
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
