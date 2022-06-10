//
//  UITextView+Placeholder.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/08.
//

import Foundation
import UIKit

extension UITextView {
    //Why does the function below for the commenttextfield need an adjusted frame origin, but not the function further down for the posts?
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
    
    func addAndReturnPlaceholderLabelTwo(withText text: String) -> UILabel {
        let placeholderLabel = UILabel()
        placeholderLabel.text = text
        placeholderLabel.font = self.font
        placeholderLabel.sizeToFit()
        addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 0, y: 9)
        placeholderLabel.textColor = UIColor.placeholderText
        placeholderLabel.isHidden = !self.text.isEmpty
        return placeholderLabel
    }
}
