//
//  ToggleButton.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/2/22.
//

import Foundation

class ToggleButton: UIButton {
    var isSelectedImage: UIImage!
    var isSelectedTitle: String!
    var isNotSelectedImage: UIImage!
    var isNotSelectedTitle: String!
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                setImage(isSelectedImage, for: .normal)
                setTitle(isSelectedTitle, for: .normal)
            } else {
                setImage(isNotSelectedImage, for: .normal)
                setTitle(isNotSelectedTitle, for: .normal)
            }
        }
    }
}
