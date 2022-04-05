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
}
