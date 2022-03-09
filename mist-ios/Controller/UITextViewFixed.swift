//
//  UITextViewFixed.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/08.
//

import Foundation
import UIKit

@IBDesignable class UITextViewFixed: UITextView {
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    func setup() {
        textContainerInset = UIEdgeInsets.zero
        textContainer.lineFragmentPadding = 0
    }
}
