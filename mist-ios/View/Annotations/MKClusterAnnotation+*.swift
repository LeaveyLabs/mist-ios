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
                title = getMostCommonAnnotationLocation(among: memberAnnotations)
                subtitle = String(memberAnnotations.count) + " mists"
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
        if cameraDistance < MapViewController.ANNOTATION_ZOOM_THRESHOLD {
            if !isHotspot {
                isHotspot = true
            }
        } else {
            if isHotspot {
                isHotspot = false
            }
        }
    }
    
    //well, this should be O(n) time
    //what if there's 50 annotations?
    //for now, since we don't let them use custom, we'll just choose the top location
    func getMostCommonAnnotationLocation(among memberAnnotations: [MKAnnotation]) -> String? {
        return (memberAnnotations.first { $0 .isKind(of: PostAnnotation.self) } as? PostAnnotation)?.post.location_description
    }
}
