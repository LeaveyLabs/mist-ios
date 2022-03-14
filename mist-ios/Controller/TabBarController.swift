//
//  TabBarController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad(){
        delegate = self;
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.title == "dummy" {
            print("dummy");
//           let vc =  ProfileViewController() this code was not working for some reason
            let vc = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewPostNavigation)
            vc.modalPresentationStyle = .fullScreen
           self.present(vc, animated: true, completion: nil)
           return false
        }
        return true
    }

}
