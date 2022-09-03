//
//  NewPostContext.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/30.
//

import Foundation
import MapKit

struct NewPostContext {
    static var pin: CLLocationCoordinate2D?
    static var timestamp: Double?
    static var title: String = ""
    static var body: String = ""
    static var locationName: String = ""
    
    static func clear() {
        pin = nil
        timestamp = nil
        title = ""
        body = ""
        locationName = ""
    }
}
