//
//  UISearchBar+CenterText.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/17/22.
//

import Foundation

extension UISearchBar {
    
    func centerText() {
        //get the sizes
        let searchBarWidth = self.frame.width
        let iconWidth = searchTextField.leftView!.frame.width + 8
        
        var textWidth: CGFloat
        
        if let searchText = searchTextField.attributedText, searchText.length != 0 {
            textWidth = searchText.size().width
            textWidth = min(textWidth, searchBarWidth-70) //if the text is too long
        } else {
            textWidth = searchTextField.attributedPlaceholder!.size().width
        }
        let offset = UIOffset(horizontal: ((searchBarWidth / 2) - (textWidth / 2) - iconWidth) - 2, vertical: 0) //-2 to slightly tip it towards the left to make the text feel more balanced
        self.setPositionAdjustment(offset, for: .search)
    }
    
}
