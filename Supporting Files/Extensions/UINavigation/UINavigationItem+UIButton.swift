//
//  UINavigationItem+UIButton.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/22/22.
//

import UIKit

extension UINavigationItem {
    
    func addRegularButtonAsBarButtonItem(_ button: UIButton) {
        let accountBarItem = UIBarButtonItem(customView: button)
        accountBarItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        accountBarItem.customView?.heightAnchor.constraint(equalToConstant: button.frame.height).isActive = true
        accountBarItem.customView?.widthAnchor.constraint(equalToConstant: button.frame.width).isActive = true
        rightBarButtonItem = accountBarItem
    }
}
