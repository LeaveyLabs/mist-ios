//
//  CustomTabBarController.swift
//  CustomTabBar
//
//  Created by Keihan Kamangar on 2021-06-07.
//

import UIKit

class CustomTabBarController: UITabBarController {
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        print("TBC IS LOAD")

        guard let tabBar = self.tabBar as? SpecialTabBar else { return }

        print("TBC DID LOAD")

        tabBar.didTapButton = { [unowned self] in
            self.routeToCreateNewAd()
        }
    }
    
    func routeToCreateNewAd() {
        let vc = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewPostNavigation)
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
}

// MARK: - UITabBarController Delegate
extension CustomTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Method #1: Thew middle view controller should have a title of dummy
        if viewController.title == "dummy" {
           return false
        }
        
        // Method #2
//        guard let selectedIndex = tabBarController.viewControllers?.firstIndex(of: viewController) else {
//            return true
//        }
//        if selectedIndex == 1 {
//            return false
//        }
        return true
    }
}
