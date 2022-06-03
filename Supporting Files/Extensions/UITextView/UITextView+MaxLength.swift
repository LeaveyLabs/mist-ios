//
//  UITextView+MaxLength.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/03.
//

import Foundation

extension UITextView {
    
    // This function handles the shouldChangeTextIn delegate funciton of UITextView

    func shouldChangeTextGivenMaxLengthOf(_ maxLength: Int, _ range: NSRange, _ string: String) -> Bool {
        guard let textViewText = self.text,
            let rangeOfTextToReplace = Range(range, in: textViewText) else {
                return false
        }
        let substringToReplace = textViewText[rangeOfTextToReplace]
        let count = textViewText.count - substringToReplace.count + string.count
        return count <= maxLength
    }
}
