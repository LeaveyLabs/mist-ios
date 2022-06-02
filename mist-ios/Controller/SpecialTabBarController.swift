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
        delegate = self
    }
}

// MARK: - UITabBarController Delegate
extension SpecialTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Method #1: Thew middle view controller should have a title of dummy
        if viewController.title == "dummy" {
           return false
        }
        
        // Method #2: Not in use
//        guard let selectedIndex = tabBarController.viewControllers?.firstIndex(of: viewController) else {
//            return true
//        }
//        if selectedIndex == 1 {
//            return false
//        }
        return true
    }
}
