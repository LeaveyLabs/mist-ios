//
//  CLLocationCoordinate.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/28/22.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

}
