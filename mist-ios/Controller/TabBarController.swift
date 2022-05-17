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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    /*
     Send up a "NewPostNavigation" modal view when the middle "plus" tab bar button is pressed.
     The view controller which is connected to the middle "plus" button should be called "dummy"
    */
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.title == "dummy" {
//            handleTouchTabbarCenter() //only present NewPostVC if the actual button is pressed, not just around the button
           return false
        }
        return true
    }
    
    @objc func handleTouchTabbarCenter() {
          let vc = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewPostNavigation)
          vc.modalPresentationStyle = .fullScreen
         self.present(vc, animated: true, completion: nil)
    }

    //https://stackoverflow.com/questions/30527738/how-do-we-create-a-bigger-center-uitabbar-item
    func addCenterButton(withImage buttonImage : UIImage) {
        centerButton = UIButton(type: .custom)
        centerButton.adjustsImageWhenHighlighted = false //deprecated, but only for the new "UIButtonConfiguration" buttons, which we're not using here
        centerButton.frame = CGRect(x: 0.0, y: 0.0, width: buttonImage.size.width, height: buttonImage.size.height)
        centerButton.translatesAutoresizingMaskIntoConstraints = false
        tabBar.addSubview(centerButton)
        NSLayoutConstraint.activate([
            centerButton.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: -30),
            centerButton.centerXAnchor.constraint(equalTo: tabBar.centerXAnchor, constant: 0),
        ])
        
        centerButton.setBackgroundImage(buttonImage, for: .normal)
        centerButton.isUserInteractionEnabled = true
        centerButton.addTarget(self, action: #selector(handleTouchTabbarCenter), for: .touchUpInside)
  }

}
