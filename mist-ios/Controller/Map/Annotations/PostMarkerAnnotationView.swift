//
//  PostMarkerAnnotationView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/08.
//

import Foundation
import MapKit

final class PostMarkerAnnotationView: MKMarkerAnnotationView {
    
    var onSelect: (() -> Void)?
    
    override var annotation: MKAnnotation? {
        willSet {
            animatesWhenAdded = true
            canShowCallout = false
            markerTintColor = mistUIColor()
            glyphImage = UIImage(named: "mist-heart-pink-padded")
            displayPriority = .defaultLow
            displayPriority = .required
        }
    }
    
    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Was trying to intercept the animation for MKMarkerAnnotationView to slow it down... to now avail
    override func setSelected(_ selected: Bool, animated: Bool) {
//    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//        super.setSelected(false, animated: false)
//    }
  }
}
