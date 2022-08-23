//
//  UITextView+PreventPeriod.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/7/22.
//

import Foundation

extension UITextView {
    
    func shouldPreventDoubleSpaceTurnsIntoPeriodShortcut(_ range: NSRange, _ text: String) -> Bool {
        if range.location > 0 && text.count > 0
            {
                let whitespace = CharacterSet.whitespaces
                
                let start = text.unicodeScalars.startIndex
                let location = self.text.unicodeScalars.index(self.text.unicodeScalars.startIndex, offsetBy: range.location - 1)
                
                //Check if a space follows a space
                if whitespace.contains(text.unicodeScalars[start]) && whitespace.contains(self.text.unicodeScalars[location])
                {
                    //Manually replace the space with your own space, programmatically
                    self.text = (self.text as NSString).replacingCharacters(in: range, with: " ")
                    
                    //Make sure you update the text caret to reflect the programmatic change to the text view
                    self.selectedRange = NSMakeRange(range.location + 1, 0)
                    
                    //Tell UIKit not to insert its space, because you've just inserted your own
                    return false
                }
            }
            
            return true
    }
}


