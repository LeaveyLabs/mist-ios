//
//  TabBarController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    var centerButton: UIButton?
    
    override func viewDidLoad(){
        delegate = self;
        if let submitButtonImage = UIImage(named: "submitbutton") {
            self.addCenterButton(withImage: submitButtonImage, highlightImage: submitButtonImage)
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
    func addCenterButton(withImage buttonImage : UIImage, highlightImage: UIImage) {
      self.centerButton = UIButton(type: .custom)
      self.centerButton?.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin]
      self.centerButton?.frame = CGRect(x: 0.0, y: 0.0, width: buttonImage.size.width, height: buttonImage.size.height)
      self.centerButton?.setBackgroundImage(buttonImage, for: .normal)
      self.centerButton?.setBackgroundImage(highlightImage, for: .highlighted)
      self.centerButton?.isUserInteractionEnabled = true

      let heightdif: CGFloat = buttonImage.size.height - (self.tabBar.frame.size.height);

      if (heightdif < 0){
          //the line below wasnt working...
//          self.centerButton?.center = (self.tabBar.center)
          
          //... so i copied these three lines from the else block below
          var center: CGPoint = (self.tabBar.center)
          center.y = center.y - 50
          self.centerButton?.center = center
          
      }
      else{
          var center: CGPoint = (self.tabBar.center)
          center.y = center.y - 50
          self.centerButton?.center = center
      }

      self.view.addSubview(self.centerButton!)
      self.tabBar.bringSubviewToFront(self.centerButton!)

      self.centerButton?.addTarget(self, action: #selector(handleTouchTabbarCenter), for: .touchUpInside)
  }

}
