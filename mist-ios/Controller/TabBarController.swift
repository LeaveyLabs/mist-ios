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
    
    /*
     Send up a "NewPostNavigation" modal view when the middle "plus" tab bar button is pressed.
     The view controller which is connected to the middle "plus" button should be called "dummy"
    */
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.title == "dummy" {
            print("dummy");
            let vc = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewPostNavigation)
            vc.modalPresentationStyle = .fullScreen
           self.present(vc, animated: true, completion: nil)
           return false
        }
        return true
    }

}
