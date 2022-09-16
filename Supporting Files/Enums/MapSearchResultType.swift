//
//  MapSearchScope.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/08.
//

import Foundation

enum MapSearchResultType: Int, CaseIterable {
    case nearby // 0
    case containing // 0 disabling this for now by setting searchSuggestionsVC to only allow display the first type of MapSearchResultTYpe
    
    var sectionName : String {
        switch self {
        case .containing:
            return "" //"mists containing:"
        case .nearby:
            return "suggested places:"
        }
    }
    
    static func randomPlaceholder() -> String {
        return ["usc village starbucks",
                "literatea",
                "dulce",
                "leavey library",
                "old annenberg",
                "doheny library",
                "the 9-0",
                "cava",
                "mccarthy quad",
                "pardee tower",
                "tutor campus center",
                "iovine and young academy",
                "seeley g. mudd",
                "lyon center",
                "village fitness center",
                "trader joe's",
                "spudnuts",
                "trousdale pkwy",
                "sunlife",
                "insomnia cookies"
//                "green eyes",
//                "kinda tall",
                ].randomElement()!
    }
}

