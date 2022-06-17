//
//  MapSearchScope.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/08.
//

import Foundation

enum MapSearchResultType: Int, CaseIterable {
    case containing // 0
    case nearby // 1
    
    var sectionName : String {
        switch self {
        case .containing:
            return "Mists containing:"
        case .nearby:
            return "Mists nearby:"
        }
    }
    
    static func randomPlaceholder() -> String {
        return ["USC Village Starbucks",
                "Literatea",
                "Dulce",
                "Leavey Library",
                "Old Annenberg",
                "Doheny Lawn",
                "The 9-0",
                "Green eyes",
                "Kinda tall",
                "Red northface backpack",
                "Kevin",].randomElement()!
    }
}

