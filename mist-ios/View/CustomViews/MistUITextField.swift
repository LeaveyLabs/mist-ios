//
//  MistUITextField.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import Foundation
import UIKit

@IBDesignable
class MistUITextField: UITextField {

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }

    func setup() {
        font = UIFont(name: Constants.Font.Medium, size: font!.pointSize)
    }

}
