//
//  UIView+Shadow.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/04.
//

import Foundation
import UIKit

//https://stackoverflow.com/questions/39624675/add-shadow-on-uiview-using-swift-3
func applyShadowOnView(_ view: UIView) {
    view.layer.shadowColor = UIColor.darkGray.cgColor
    view.layer.shadowOpacity = 0.4
    view.layer.shadowOffset = .zero
    view.layer.shadowRadius = 3
    if view .isKind(of: UIButton.self) {
        view.layer.masksToBounds = false
    }
}

extension UIView {
    func applyLightLeftShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.10, x: -2, y: 2, blur: 2, spread: 0)
    }
    
    func applyLightMediumShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.2, x: 0, y: 1, blur: 5, spread: 0)
    }
    
    func applyMediumShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.3, x: 0, y: 1, blur: 5, spread: 0)
    }
    
    func applyLightShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.15, x: 0, y: 1, blur: 5, spread: 0)
    }
    
    func applyLightRightLeaningShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.10, x: 2, y: 2, blur: 5, spread: 0)
    }
    
    func applyMediumRightLeaningShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.2, x: 2, y: 2, blur: 5, spread: 0)
    }
    
    func applyMediumLeftLeaningShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.2, x: -2, y: 2, blur: 5, spread: 0)
    }
    
    func applyMediumBottomLeaningShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.3, x: 0, y: 2, blur: 5, spread: 0)
    }
    
    func applyMediumTopOnlyShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.15, x: 0, y: -5, blur: 7, spread: 0)
    }
    
    func applyMediumBottomOnlyShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.15, x: 0, y: 5, blur: 7, spread: 0)
    }
    
    func applyLightBottomOnlyShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.08, x: 0, y: 5, blur: 5, spread: 0)
    }
    
    func applyVeryLightBottomOnlyShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.04, x: 0, y: 3, blur: 5, spread: 0)
    }
    
    func applyLightTopOnlyShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.15, x: 0, y: -4, blur: 5, spread: 0)
    }
    
    func applyLightLeftOnlyShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.15, x: -4, y: 0, blur: 5, spread: 0)
    }
    
}


extension CALayer {
  func applySketchShadow(
    color: UIColor = .black,
    alpha: Float = 0.5,
    x: CGFloat = 0,
    y: CGFloat = 2,
    blur: CGFloat = 4,
    spread: CGFloat = 0)
  {
    masksToBounds = false
    shadowColor = color.cgColor
    shadowOpacity = alpha
    shadowOffset = CGSize(width: x, height: y)
    shadowRadius = blur / 2.0
    if spread == 0 {
      shadowPath = nil
    } else {
      let dx = -spread
      let rect = bounds.insetBy(dx: dx, dy: dx)
      shadowPath = UIBezierPath(rect: rect).cgPath
    }
  }
}
