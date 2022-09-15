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
    
    func updateClusterTitle() {
        title = getMostCommonAnnotationLocation(among: memberAnnotations)
        subtitle = ""
    }
    
    func getMostCommonAnnotationLocation(among memberAnnotations: [MKAnnotation]) -> String? {
        return (memberAnnotations.first { $0 .isKind(of: PostAnnotation.self) } as? PostAnnotation)?.post.title
    }
}
