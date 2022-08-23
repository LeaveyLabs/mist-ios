//
//  ToggleButton.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/2/22.
//

import Foundation

class ToggleButton: UIButton {
    var selectedImage: UIImage!
    var selectedTitle: String!
    var notSelectedImage: UIImage!
    var notSelectedTitle: String!
    var selectedTintColor: UIColor = .black
    var notSelectedTintColor: UIColor = .black
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                tintColor = selectedTintColor
                setImage(selectedImage, for: .normal)
                setTitle(selectedTitle, for: .normal)
            } else {
                tintColor = notSelectedTintColor
                setImage(notSelectedImage, for: .normal)
                setTitle(notSelectedTitle, for: .normal)
            }
        }
    }
}
