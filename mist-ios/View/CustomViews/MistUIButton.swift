//
//  MistUIButton.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import Foundation
import UIKit

@IBDesignable
class MistUIButton: UIButton {
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    
    func setup() {
        self.titleLabel!.font = UIFont(name: Constants.Font.Medium, size: self.titleLabel!.font.pointSize)
    }
}
