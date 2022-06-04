//
//  PostMarkerAnnotationView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/08.
//

import Foundation
import MapKit

//TODO: create separate annotationview for pinmap

// Customize annotaiton view
//https://stackoverflow.com/questions/56311852/mkmapview-not-clustering-annotation-on-zooming-out-map-in-swift

final class PostAnnotationView: MKMarkerAnnotationView {
    
    var postCalloutView: UIView? // the postAnnotationView's callout view
    
    // MapView annotation views are reused like TableView cells, so everytime they're set, you should prepare them
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
        super.init(coder: aDecoder)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            self.postCalloutView?.removeFromSuperview() // This shouldn't be needed, but just in case

            glyphTintColor = mistUIColor() //this is needed bc for some reason the glyph tint color turns grey even with the mist-heart-pink icon
            markerTintColor = mistSecondaryUIColor()
        } else {
            glyphTintColor = .white
            markerTintColor = mistUIColor()
            
            if let postCalloutView = postCalloutView {
                postCalloutView.fadeOut(duration: 0.5, delay: 0, completion: { Bool in
                    postCalloutView.isHidden = true
                    postCalloutView.removeFromSuperview()
                })
            }
        }
    }
    
    // Called by the viewController, because the delay differs based on if the post was just uploaded or if it was jut clicked on
    func loadPostView(withDelay delay: Double) {
        let postCalloutView = PostCalloutView(annotation: annotation as! PostAnnotation) // Initializes as hidden
        postCalloutView.add(toPostAnnotationView: self) // Sets up constraints, too
        self.postCalloutView = postCalloutView
        
        postCalloutView.fadeIn(duration: 0.2, delay: delay-0.15)
    }
    
    // Make sure that if the cell is reused that we remove it from the super view.
    // I think this handles the case where a postView has been rendered for a postannotationview,
    // but then the post annotationview goes offscreen and that same annotationview is reused
    
    override func prepareForReuse() {
        super.prepareForReuse()
        postCalloutView?.removeFromSuperview()
    }
    
    // MARK: - Detect taps on callout (postView)

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitAnnotationView = super.hitTest(point, with: event) {
            return hitAnnotationView
        }

        // If it wasn't MKMarketerAnnotationView, then the hit view must postView, the the classes's only subview
        if let postView = postCalloutView {
            let pointInPostView = convert(point, to: postView)
            return postView.hitTest(pointInPostView, with: event)
        }

        return nil
    }
}
