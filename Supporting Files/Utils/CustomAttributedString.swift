//
//  AttributedString.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/26.
//

import Foundation

struct CustomAttributedString {
    static func createFor(text: String, fontName: String, size: CGFloat) -> NSMutableAttributedString {
        let customAttributes = [NSAttributedString.Key.font: UIFont(name: fontName, size: size)!]
        return NSMutableAttributedString(string: text, attributes: customAttributes)
    }
    
    static func errorMessage(errorText: String, size: CGFloat) -> NSMutableAttributedString {
        let heavyAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: size)!,
                               NSMutableAttributedString.Key.foregroundColor: UIColor.white]
        let mediumAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: size)!,
                                NSMutableAttributedString.Key.foregroundColor: UIColor.white]
        
        let errorMessageBuilder = NSMutableAttributedString()
        errorMessageBuilder.append(NSMutableAttributedString(string: "😔 Oops. ", attributes: heavyAttributes))
        errorMessageBuilder.append(NSMutableAttributedString(string: errorText, attributes: mediumAttributes))
        return errorMessageBuilder
    }
}
