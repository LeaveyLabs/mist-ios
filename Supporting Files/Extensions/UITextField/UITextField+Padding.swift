//
//  UITextField+Padding.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/24.
//

import Foundation
import UIKit

extension UITextField {
    func setLeftAndRightPadding(_ amount:CGFloat){
        setLeftPaddingPoints(amount)
        setRightPaddingPoints(amount)
    }
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}
