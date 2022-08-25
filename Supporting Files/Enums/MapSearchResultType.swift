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
            return "mists containing:"
        case .nearby:
            return "mists nearby:"
        }
    }
    
    static func randomPlaceholder() -> String {
        return ["usc village starbucks",
                "literatea",
                "dulce",
                "leavey library",
                "old annenberg",
                "doheny lawn",
                "the 9-0",
                "green eyes",
                "kinda tall",
                "red northface backpack"].randomElement()!
    }
}

