//
//  UITextView+Newline.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/30/22.
//

import Foundation

extension UITextView {
    
    func shouldAllowNewline(in existingText: String, at index: Int) -> Bool {

        // Two conditions under which to not allow a newline:
        let isFirstCharacter = index == 0
        var isThreeTimesInARow = false
        
        var isNewlineBeforeTwice = false
        let isEditingFirstTwoCharacters = index <= 1
        if !isEditingFirstTwoCharacters {
            isNewlineBeforeTwice = existingText.substring(with: index-2..<index) == "\n\n"
        }
        var isNewlineBeforeAndAfter = false
        let isEditingFirstOrLastCharacters = index == 0 || index == existingText.count
        if !isEditingFirstOrLastCharacters {
            isNewlineBeforeAndAfter = existingText.substring(with: index-1..<index) == "\n" &&
            existingText.substring(with: index..<index+1) == "\n"
        }
        var isNewlineAfterTwice = false
        let isEditingLastTwoCharacters = index >= existingText.count-1
        if !isEditingLastTwoCharacters {
            isNewlineAfterTwice = existingText.substring(with: index..<index+2) == "\n\n"
        }
        
        isThreeTimesInARow = isNewlineBeforeTwice || isNewlineBeforeAndAfter || isNewlineAfterTwice
        
        return !(isFirstCharacter || isThreeTimesInARow)
    }
    
}
