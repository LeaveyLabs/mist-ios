//
//  PostMarkerAnnotationView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/08.
//

import Foundation
import MapKit

final class PostAnnotationView: MKMarkerAnnotationView, UIGestureRecognizerDelegate {
    
    var postCalloutView: PostView? // the postAnnotationView's callout view
    
    // MapView annotation views are reused like TableView cells,
    // so everytime they're set, you should prepare them
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
        setupGestureRecognizerToPreventIBActionDelay()

    }
    private func setupGestureRecognizerToPreventIBActionDelay() {
        let quickSelectGestureRecognizer = UITapGestureRecognizer()
        quickSelectGestureRecognizer.delaysTouchesBegan = false
        quickSelectGestureRecognizer.delaysTouchesEnded = false
        quickSelectGestureRecognizer.numberOfTapsRequired = 1
        quickSelectGestureRecognizer.numberOfTouchesRequired = 1
        quickSelectGestureRecognizer.delegate = self
        addGestureRecognizer(quickSelectGestureRecognizer)
    }
    
    var mapView: MKMapView? {
        var view = superview
        while view != nil {
            if let mapView = view as? MKMapView { return mapView }
            view = view?.superview
        }
        return nil
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        mapView?.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mapView?.isZoomEnabled = true
        }
        return false
        //return (! [yourButton pointInside:[touch locationInView:yourButton] withEvent:nil]); this code is necessary in case the gesture recognizer is preventing the button press
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
        
    override func setSelected(_ selected: Bool, animated: Bool) {        
        super.setSelected(selected, animated: animated)

        if selected {
            glyphTintColor = mistUIColor() //this is needed bc for some reason the glyph tint color turns grey even with the mist-heart-pink icon
            markerTintColor = mistSecondaryUIColor()
            if let postCalloutView = postCalloutView {
                postCalloutView.removeFromSuperview() // This shouldn't be needed, but just in case
            }
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
    func loadPostView(on mapView: MKMapView, withDelay delay: Double) {
        postCalloutView = PostView()
        guard let postCalloutView = postCalloutView else {return}
        
        let postAnnotation = annotation as! PostAnnotation
        postCalloutView.configurePost(post: postAnnotation.post, bubbleTrianglePosition: .bottom)
        postCalloutView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(postCalloutView)
        
        NSLayoutConstraint.activate([
            postCalloutView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -100),
            postCalloutView.widthAnchor.constraint(equalTo: mapView.widthAnchor, constant: -30),
            postCalloutView.heightAnchor.constraint(lessThanOrEqualTo: mapView.heightAnchor, multiplier: 0.54, constant: 0),
            postCalloutView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
        ])

        //Do i need to call some of these?
//        mapView!.layoutIfNeeded()
//        postCalloutView.setNeedsLayout()
        
        postCalloutView.fadeIn(duration: 0.2, delay: delay-0.15)
    }
    
    // Make sure that if the cell is reused that we remove the postCalloutView from the postAnnotationView.
    override func prepareForReuse() {
        super.prepareForReuse()
        postCalloutView?.removeFromSuperview()
    }
    
    // MARK: - Detect taps on postCalloutView

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
