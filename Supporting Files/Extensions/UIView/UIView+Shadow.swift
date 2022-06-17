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
    func applyLightShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.3, x: 0, y: 1, blur: 5, spread: 0)
    }
    
    func applyMediumShadow() {
        layer.applySketchShadow(color: .black, alpha: 0.3, x: 0, y: 1, blur: 5, spread: 0)
    }
    
    func applyMediumShadowAbove() {
        layer.applySketchShadow(color: .black, alpha: 0.3, x: 0, y: -1, blur: 5, spread: 0)
    }
    
    func applyMediumShadowBelowOnly() {
        layer.applySketchShadow(color: .black, alpha: 0.2, x: 0, y: 5, blur: 7, spread: 0)
    }
}
