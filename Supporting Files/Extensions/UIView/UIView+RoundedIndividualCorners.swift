//
//  UIView+RoundedIndividualCorners.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/11.
//

import Foundation
import UIKit

extension UIView {
    
    //This function requires the UIView to already have the proper frame (not a .zero initialized frame)
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
        layer.cornerCurve = .continuous
    }
}
