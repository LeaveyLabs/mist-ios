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
}
