//
//  UITextField+MaxCharacters.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/01.
//

import Foundation

extension UITextField {
    
    // This function handles the shouldChangeCharactersIn delegate funciton of UITextField
    // Reference: https://stackoverflow.com/questions/25223407/max-length-uitextfield

    func shouldChangeCharactersGivenMaxLengthOf(_ maxLength: Int, _ range: NSRange, _ string: String) -> Bool {
        guard let textFieldText = self.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= maxLength
    }
}

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
