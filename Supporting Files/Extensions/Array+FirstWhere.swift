//
//  Array+FirstWhere.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/4/22.
//

import Foundation

extension Array where Element: Equatable {
     // Remove first collection element that is equal to the given `object`:
     mutating func removeFirstAppearanceOf(object: Element) {
         guard let index = firstIndex(of: object) else {return}
         remove(at: index)
     }
}
