//
//  UIButton+RightSideImage.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/01.
//

import Foundation

extension UIButton {
    func setImageToRightSide() {
        imageView?.trailingAnchor.constraint(equalTo: trailingAnchor,
                                             constant: -8.0).isActive = true
        imageView?.centerYAnchor.constraint(equalTo: centerYAnchor,
                                            constant: 0.0).isActive = true
        translatesAutoresizingMaskIntoConstraints = false
        imageView?.translatesAutoresizingMaskIntoConstraints = false
    }
}
