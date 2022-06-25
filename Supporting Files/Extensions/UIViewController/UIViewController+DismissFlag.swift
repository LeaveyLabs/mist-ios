//
//  UIViewController+DismissFlag.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/21/22.
//

import Foundation

extension UIViewController {
    var isAboutToClose: Bool {
        return self.isBeingDismissed ||
               self.isMovingFromParent ||
               self.navigationController?.isBeingDismissed ?? false
    }
}
