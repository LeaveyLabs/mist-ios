//
//  CLLocationCoordinate+Distance.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/06.
//

import Foundation
import MapKit

extension CLLocationCoordinate2D {
    
    func distance(from otherCoordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let myLocation = CLLocation(latitude: self.latitude,
                                    longitude: self.longitude)
        let otherLocation = CLLocation(latitude: otherCoordinate.latitude,
                                       longitude: otherCoordinate.longitude)
        return myLocation.distance(from: otherLocation)
    }
}
