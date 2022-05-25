//
//  ButtonConfigs.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/25.
//

import Foundation
import UIKit

struct ButtonConfigs {
    let enabledTitleAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: 20)!]
    let disabledTitleAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: 20)!,
                                   NSAttributedString.Key.foregroundColor: UIColor.init(white: 1, alpha: 0.3)]

    var enabledConfig = UIButton.Configuration.filled()
    var disabledConfig = UIButton.Configuration.filled()
    
    static let shared = ButtonConfigs()

    private init() {
        enabledConfig.attributedTitle = AttributedString("Continue", attributes: AttributeContainer(enabledTitleAttributes))
        enabledConfig.cornerStyle = .capsule
        enabledConfig.background.backgroundColor = mistUIColor()
        enabledConfig.contentInsets = .init(top: 10, leading: 0, bottom: 10, trailing: 0) // Custom size
        enabledConfig.imagePadding = 5 // Pads the activity indicator
        
        disabledConfig.attributedTitle = AttributedString("Continue", attributes: AttributeContainer(disabledTitleAttributes))
        disabledConfig.cornerStyle = .capsule
        disabledConfig.background.backgroundColor = mistUIColor()
        disabledConfig.contentInsets = .init(top: 10, leading: 0, bottom: 10, trailing: 0) // Custom size
        disabledConfig.imagePadding = 5 // Pads the activity indicator
    }
}
