//
//  CLLocationCoordiante+Midway.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/06.
//

import Foundation
import MapKit

extension CLLocationCoordinate2D {
    
    func geographicMidpoint(betweenCoordinates userGivenCoordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        var allCoordinates = userGivenCoordinates
        allCoordinates.append(self)
        return CLLocationCoordinate2D.geographicMidpoint(betweenCoordinates: allCoordinates)
        
//        var coordinates = userGivenCoordinates
//        coordinates.append(self)
//        guard coordinates.count > 1 else {
//            return coordinates.first ?? // return the only coordinate
//                CLLocationCoordinate2D(latitude: 0, longitude: 0) // return null island if no coordinates were given
//        }
//
//        var x = Double(0)
//        var y = Double(0)
//        var z = Double(0)
//
//        for coordinate in coordinates {
//            let lat = coordinate.latitude.degreesToRadians
//            let lon = coordinate.longitude.degreesToRadians
//            x += cos(lat) * cos(lon)
//            y += cos(lat) * sin(lon)
//            z += sin(lat)
//        }
//
//        x /= Double(coordinates.count)
//        y /= Double(coordinates.count)
//        z /= Double(coordinates.count)
//
//        let lon = atan2(y, x)
//        let hyp = sqrt(x * x + y * y)
//        let lat = atan2(z, hyp)
//
//        return CLLocationCoordinate2D(latitude: lat.radiansToDegrees, longitude: lon.radiansToDegrees)
    }
    
}

extension CLLocationCoordinate2D {
    
    static func geographicMidpoint(betweenCoordinates coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        
        guard coordinates.count > 1 else {
            return coordinates.first ?? // return the only coordinate
                CLLocationCoordinate2D(latitude: 0, longitude: 0) // return null island if no coordinates were given
        }
        
        var x = Double(0)
        var y = Double(0)
        var z = Double(0)

        for coordinate in coordinates {
            let lat = coordinate.latitude.degreesToRadians
            let lon = coordinate.longitude.degreesToRadians
            x += cos(lat) * cos(lon)
            y += cos(lat) * sin(lon)
            z += sin(lat)
        }

        x /= Double(coordinates.count)
        y /= Double(coordinates.count)
        z /= Double(coordinates.count)

        let lon = atan2(y, x)
        let hyp = sqrt(x * x + y * y)
        let lat = atan2(z, hyp)

        return CLLocationCoordinate2D(latitude: lat.radiansToDegrees, longitude: lon.radiansToDegrees)
    }
    
}

extension BinaryInteger {
    var degreesToRadians: CGFloat { CGFloat(self) * .pi / 180 }
}

extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}
