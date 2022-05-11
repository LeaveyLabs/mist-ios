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
        print("TAB BAR DID APPEAR")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if tabBar.isHidden {
            centerButton.isHidden = true
        } else {
            centerButton.isHidden = false
            view.bringSubviewToFront(centerButton)
        }
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
      centerButton.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin]
      centerButton.frame = CGRect(x: 0.0, y: 0.0, width: buttonImage.size.width, height: buttonImage.size.height)
      centerButton.setBackgroundImage(buttonImage, for: .normal)
      centerButton.isUserInteractionEnabled = true

      let heightdif: CGFloat = buttonImage.size.height - (self.tabBar.frame.size.height);

      if (heightdif < 0){
          //the line below wasnt working...
//          self.centerButton?.center = (self.tabBar.center)
          
          //... so i copied these three lines from the else block below
          var center: CGPoint = (tabBar.center)
          center.y = center.y - 50
          centerButton.center = center
          
      } else {
          var center: CGPoint = (tabBar.center)
          center.y = center.y - 50
          centerButton.center = center
      }
        
        centerButton.center = tabBar.center

      tabBar.addSubview(centerButton)
      tabBar.bringSubviewToFront(centerButton)

      centerButton.addTarget(self, action: #selector(handleTouchTabbarCenter), for: .touchUpInside)
  }

}
