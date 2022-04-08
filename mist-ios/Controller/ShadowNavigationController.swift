//
//  ShadowNavigationController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/07.
//

import UIKit

class ShadowNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: add a shadow instead of a thin line on scroll. have to add the code below and then add "onscroll" in tableview
        //https://stackoverflow.com/questions/56841858/how-to-only-show-a-a-shadow-under-navigation-bar-once-user-beings-scrolling
//        self.navigationBar.layer.masksToBounds = false
//        self.navigationBar.layer.shadowColor = UIColor.lightGray.cgColor
//        self.navigationBar.layer.shadowOpacity = 0.6
//        self.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
//        self.navigationBar.layer.shadowRadius = 2
                
        //TODO: consider creating a custom navigation bar which has more white space underneath
        
        //apparently shadowImage is broken? https://developer.apple.com/forums/thread/692339
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.shadowColor = .lightGray
        standardAppearance.backgroundColor = .white
        navigationBar.standardAppearance = standardAppearance
                
        let scrollViewAppearance = UINavigationBarAppearance()
        scrollViewAppearance.shadowColor = nil
        standardAppearance.shadowImage = nil
        scrollViewAppearance.backgroundColor = .white
        navigationBar.scrollEdgeAppearance = scrollViewAppearance
    }
}
