//
//  NewPostContext.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/30.
//

import Foundation
import MapKit

struct NewPostContext {
    static var placemark: MKPlacemark?
    static var timestamp: Double?
    static var title: String = ""
    static var body: String = ""
    
    static func clear() {
        placemark = nil
        timestamp = nil
        title = ""
        body = ""
    }
}
