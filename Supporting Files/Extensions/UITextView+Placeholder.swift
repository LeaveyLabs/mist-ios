//
//  UITextView+Placeholder.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/08.
//

import Foundation
import UIKit

extension UITextView {
    func addAndReturnPlaceholderLabel(withText text: String) -> UILabel {
        let placeholderLabel = UILabel()
        placeholderLabel.text = text
        placeholderLabel.font = self.font
        placeholderLabel.sizeToFit()
        addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 10, y: 10)
        placeholderLabel.textColor = UIColor.placeholderText
        placeholderLabel.isHidden = !self.text.isEmpty
        return placeholderLabel
    }
}
