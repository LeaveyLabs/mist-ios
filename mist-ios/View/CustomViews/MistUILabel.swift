//
//  MistUILabel.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import Foundation
import UIKit

//TODO: apple suggests you create a separate target for designable classes
//https://stackoverflow.com/questions/34593734/uilabel-subclass-appearance-in-storyboard

@IBDesignable
class MistUILabel: UILabel {

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }

    func setup() {
        font = UIFont(name: Constants.defaultFont, size: font.pointSize)
    }

}
