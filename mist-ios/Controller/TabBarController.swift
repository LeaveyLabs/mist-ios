//
//  TabBarController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    var centerButton: UIButton!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        delegate = self;
        addCenterButton(withImage: UIImage(named: "submitbutton")!)
    
//        let tabBar = self.tabBar as! CustomTabBar
//
//        guard let tabBar = self.tabBar as? CustomTabBar else {
//            print("custom tab bar failed")
//            return
//        }
    }
    
    /*
     Send up a "NewPostNavigation" modal view when the middle "plus" tab bar button is pressed.
     The view controller which is connected to the middle "plus" button should be called "dummy"
    */
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Method #1: Thew middle view controller should have a title of dummy
        if viewController.title == "dummy" {
           return false
        }
        
        // Method #2
        guard let selectedIndex = tabBarController.viewControllers?.firstIndex(of: viewController) else {
            return true
        }
        if selectedIndex == 1 {
            return false
        }
        return true
    }
    
    @objc func handleTouchTabbarCenter() {
          let vc = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewPostNavigation)
          vc.modalPresentationStyle = .fullScreen
         self.present(vc, animated: true, completion: nil)
    }

    func addCenterButton(withImage buttonImage : UIImage) {
        centerButton = UIButton()
        centerButton.adjustsImageWhenHighlighted = false //deprecated, but only for the new "UIButtonConfiguration" buttons, which we're not using here
//        centerButton.frame = CGRect(x: 0.0, y: 0.0, width: buttonImage.size.width, height: buttonImage.size.height)
        centerButton.frame.size = CGSize(width: 48, height: 48)
        centerButton.translatesAutoresizingMaskIntoConstraints = false
        centerButton.setImage(buttonImage, for: .normal)

        print(tabBar.clipsToBounds)
        
//        guard let tabBar = self.tabBar as? CustomTabBar else { return }

        tabBar.addSubview(centerButton)
        tabBar.bringSubviewToFront(centerButton)
        
        tabBar.layer.shadowColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1).cgColor
        tabBar.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        tabBar.layer.shadowRadius = 4.0
        tabBar.layer.shadowOpacity = 0.4
        tabBar.layer.masksToBounds = false
        
        NSLayoutConstraint.activate([
            centerButton.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: -30),
            centerButton.centerXAnchor.constraint(equalTo: tabBar.centerXAnchor, constant: 0),
        ])
        
        centerButton.isUserInteractionEnabled = true
        centerButton.addTarget(self, action: #selector(handleTouchTabbarCenter), for: .touchUpInside)
        
  }
}

