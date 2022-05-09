//
//  PostMarkerAnnotationView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/08.
//

import Foundation
import MapKit

// Customize annotaiton view
//https://stackoverflow.com/questions/56311852/mkmapview-not-clustering-annotation-on-zooming-out-map-in-swift

final class PostMarkerAnnotationView: MKMarkerAnnotationView {
    
    var onSelect: (() -> Void)?
    
    override var annotation: MKAnnotation? {
        willSet {
            animatesWhenAdded = true
            canShowCallout = false
            markerTintColor = mistUIColor()
            glyphImage = UIImage(named: "mist-heart-pink-padded")
            displayPriority = .defaultLow
            clusteringIdentifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier
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
    // The best solution is probably to just make your own custom anotation view and own custom animations along with it
    override func setSelected(_ selected: Bool, animated: Bool) {
//    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//        super.setSelected(false, animated: false)
//    }
  }
}
