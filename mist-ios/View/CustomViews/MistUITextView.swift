//
//  UITextViewFixed.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/08.
//

import Foundation
import UIKit

@IBDesignable
class MistUITextView: UITextView {
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    
    func setup() {
        font = UIFont(name: Constants.Font.Medium, size: self.font!.pointSize)
        textContainerInset = UIEdgeInsets.zero
        textContainer.lineFragmentPadding = 0
    }
}
