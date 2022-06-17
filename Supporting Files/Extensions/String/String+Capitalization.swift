//
//  String+Capitalization.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/16/22.
//

import Foundation

extension String {
    func capitalizeFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizeFirstLetter()
    }
}
