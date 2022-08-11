//
//  ButtonConfigs.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/25.
//

import Foundation
import UIKit

struct ButtonConfigs {
    static let enabledTitleAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: 24)!]
    static let disabledTitleAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: 24)!]
        
    static func enabledConfig(title: String) -> UIButton.Configuration {
        var enabledConfig = UIButton.Configuration.filled()
        enabledConfig.attributedTitle = AttributedString(title, attributes: AttributeContainer(enabledTitleAttributes))
        enabledConfig.cornerStyle = .capsule
        enabledConfig.background.backgroundColor = mistUIColor()
//        enabledConfig.contentInsets = .init(top: 10, leading: 0, bottom: 10, trailing: 0) // Custom size
        //Note: must set contentInsets to custom in storyboard in order to lead/trail align
        enabledConfig.imagePadding = 5 // Pads the activity indicator
        return enabledConfig
    }
    
    static func disabledConfig(title: String) -> UIButton.Configuration {
        var disabledConfig = UIButton.Configuration.filled()
        disabledConfig.attributedTitle = AttributedString(title, attributes: AttributeContainer(disabledTitleAttributes))
        disabledConfig.cornerStyle = .capsule
        disabledConfig.background.backgroundColor = mistUIColor()
//        disabledConfig.contentInsets = .init(top: 10, leading: 0, bottom: 10, trailing: 0) // Custom size
        disabledConfig.imagePadding = 5 // Pads the activity indicator
        return disabledConfig
    }
}
