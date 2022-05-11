//
//  ClusterAnnotation.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/08.
//

import Foundation
import UIKit
import MapKit

extension MKClusterAnnotation {

    @IBInspectable var isHotspot : Bool {
        set {
            if newValue {
                if let postAnnotation = memberAnnotations[0] as? PostAnnotation {
                    title = postAnnotation.post!.location_description!
                }
                subtitle = String(memberAnnotations.count) + " missed connections"
                
            } else {
                title = memberAnnotations[0].title!
                subtitle = "+" + String(memberAnnotations.count-1) + " more"
            }
        }

        get {
            return !(subtitle![subtitle!.startIndex] == "+")
        }
    }
    
    func updateIsHotspot(cameraDistance: Double) {
        if cameraDistance < 600 {
            if !isHotspot {
                isHotspot = true
            }
        } else {
            if isHotspot {
                isHotspot = false
            }
        }
    }
}
