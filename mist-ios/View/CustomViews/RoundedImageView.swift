//
//  RoundedImageView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/29.
//

import Foundation
import UIKit

@IBDesignable class RoundedImageView: UIImageView {

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }

    override func layoutSubviews() {
        setup()
        super.layoutSubviews()
    }

    func setup() {
        frame.size.height = frame.size.width
        layer.cornerRadius = frame.size.height / 2
        layer.cornerCurve = .continuous
        clipsToBounds = true
    }
}
