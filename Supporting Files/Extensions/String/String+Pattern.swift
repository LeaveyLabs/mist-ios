//
//  String+Pattern.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/6/22.
//

import Foundation

//Usage:
//guard let text = textField.text else { return }
//textField.text = text.applyPatternOnNumbers(pattern: "+# (###) ###-####", replacmentCharacter: "#")

extension String {
    func applyPatternOnNumbers(pattern: String, replacementCharacter: Character) -> String {
        var pureNumber = self.replacingOccurrences( of: "[^0-9]", with: "", options: .regularExpression)
        for index in 0 ..< pattern.count {
            guard index < pureNumber.count else { return pureNumber }
            let stringIndex = String.Index(utf16Offset: index, in: pattern)
            let patternCharacter = pattern[stringIndex]
            guard patternCharacter != replacementCharacter else { continue }
            pureNumber.insert(patternCharacter, at: stringIndex)
        }
        return pureNumber
    }
}
