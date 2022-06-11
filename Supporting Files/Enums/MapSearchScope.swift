//
//  MapSearchScope.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/08.
//

import Foundation

enum MapSearchScope: Int, CaseIterable {
    case locatedAt // 0
    case containing // 1
    
    var displayName : String {
        switch self {
        case .locatedAt:
            return "Located at"
        case .containing:
            return "Containing"
        }
    }
    
    var randomPlaceholder: String {
        switch self {
        case .locatedAt:
            return ["USC Village Starbucks",
                    "Literatea",
                    "Dulce",
                    "Leavey Library",
                    "Old Annenberg",
                    "Doheny Lawn",
                    "The 9-0",].randomElement()!
        case .containing:
            return ["Green eyes",
                    "Kinda tall",
                    "Red northface backpack",
                    "Kevin",].randomElement()!
        }
    }
}

