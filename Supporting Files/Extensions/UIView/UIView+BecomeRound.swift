//
//  UIView+BecomeRound.swift
//  uscdatingclub-ios
//
//  Created by Adam Novak on 2022/12/28.
//

import UIKit

extension UIView {
    
    func becomeRound() {
        self.layer.cornerRadius = self.bounds.width / 2
        self.layer.cornerCurve = .continuous
    }
    
}

extension UIView {
    
    func roundCornersViaCornerRadius(radius: CGFloat) {
        layer.cornerCurve = .continuous
        layer.cornerRadius = radius
    }
}
