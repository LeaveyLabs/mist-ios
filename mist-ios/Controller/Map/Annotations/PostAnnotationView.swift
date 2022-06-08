//
//  PostMarkerAnnotationView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/08.
//

import Foundation
import MapKit

protocol AnnotationViewSwipeDelegate {
    func handlePostViewSwipeLeft()
    func handlePostViewSwipeRight()
}

final class PostAnnotationView: MKMarkerAnnotationView {
    
    var postCalloutView: PostView? // the postAnnotationView's callout view
    var mapView: MKMapView? {
        var view = superview
        while view != nil {
            if let mapView = view as? MKMapView { return mapView }
            view = view?.superview
        }
        return nil
    }
    
    // Panning gesture
    var originalPanLocation: CGPoint = .init(x: 0, y: 0)
    var swipeDelegate: AnnotationViewSwipeDelegate?
    
    // MapView annotation views are reused like TableView cells,
    // so everytime they're set, you should prepare them
    override var annotation: MKAnnotation? {
        willSet {
            animatesWhenAdded = true
            canShowCallout = false
            glyphImage = UIImage(named: "mist-heart-pink-padded")
            glyphTintColor = .white
            markerTintColor = mistUIColor()
            displayPriority = .defaultLow
            clusteringIdentifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier
        }
    }
    
    //MARK: - Initializaiton
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupPanGesture()
        setupTapGestureRecognizerToPreventInteractionDelay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Make sure that if the cell is reused that we remove the postCalloutView from the postAnnotationView.
    override func prepareForReuse() {
        super.prepareForReuse()
        postCalloutView?.removeFromSuperview()
    }
    
    //MARK: - User Interaction
        
    override func setSelected(_ selected: Bool, animated: Bool) {        
        super.setSelected(selected, animated: animated)

        if selected {
            glyphTintColor = mistUIColor()
            markerTintColor = mistSecondaryUIColor()
            if let postCalloutView = postCalloutView {
                postCalloutView.removeFromSuperview() // This shouldn't be needed, but just in case
            }
        } else {
            glyphTintColor = .white
            markerTintColor = mistUIColor()
            if let postCalloutView = postCalloutView {
                postCalloutView.fadeOut(duration: 0.25, delay: 0, completion: { Bool in
                    postCalloutView.isHidden = true
                    postCalloutView.removeFromSuperview()
                })
            }
        }
    }
    
    // For detecting taps on postCalloutView subview
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
    
    //MARK: - Helpers
    
    // Called by the viewController, because the delay differs based on if the post was just uploaded or if it was jut clicked on
    func loadPostView(on mapView: MKMapView,
                      withDelay delay: Double,
                      withPostDelegate postDelegate: ExploreMapViewController) {
        swipeDelegate = postDelegate

        postCalloutView = PostView()
        guard let postCalloutView = postCalloutView else {return}
        
        postCalloutView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(postCalloutView)
        
        NSLayoutConstraint.activate([
            postCalloutView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -100),
            postCalloutView.widthAnchor.constraint(equalTo: mapView.widthAnchor, constant: -30),
            postCalloutView.heightAnchor.constraint(lessThanOrEqualTo: mapView.heightAnchor, multiplier: 0.75, constant: -140),
            postCalloutView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
        ])
        
        let postAnnotation = annotation as! PostAnnotation
        postCalloutView.configurePost(post: postAnnotation.post, bubbleTrianglePosition: .bottom)
        postCalloutView.postDelegate = postDelegate

        //Do i need to call some of these? I dont think so.
        mapView.layoutIfNeeded()
        postCalloutView.setNeedsLayout()
        
        postCalloutView.alpha = 0
        postCalloutView.isHidden = true
//        DispatchQueue.main.asyncAfter(deadline: .now() + delay - 0.15) {
//
//        }
        postCalloutView.fadeIn(duration: 0.2, delay: delay - 0.15)
    }

}

//MARK: - PreventAnnotationViewInteractionDelay
// Similar to the tapGestureRecognizer we added to mapView to prevent a delay when tapping annotation view,
// we also add a tapGestureRecognizer here to prevent a delay when interacting w post
//https://stackoverflow.com/questions/35639388/tapping-an-mkannotation-to-select-it-is-really-slow

extension PostAnnotationView: UIGestureRecognizerDelegate {
    
    private func setupTapGestureRecognizerToPreventInteractionDelay() {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.delaysTouchesBegan = false
        tapRecognizer.delaysTouchesEnded = false
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.delegate = self
        self.addGestureRecognizer(tapRecognizer)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        mapView?.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mapView?.isZoomEnabled = true
        }
        return false
    }
    
}

// MARK: - PanGesture

extension PostAnnotationView {
    
    // Add a pan gesture captures the panning on map and prevents the post from being dismissed
    private func setupPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gestureRecognizer:)))
        addGestureRecognizer(pan)
    }
    
    @objc func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            originalPanLocation = gestureRecognizer.location(in: postCalloutView)
            break
        case .changed:

            break
        case .ended:
            let finalPanLocation = gestureRecognizer.location(in: postCalloutView)
            let swipeLeft = originalPanLocation.x > finalPanLocation.x
            if swipeLeft {
                swipeDelegate?.handlePostViewSwipeLeft()
            } else {
                swipeDelegate?.handlePostViewSwipeRight()
            }
            break
        default:
            break
        }
    }
    
}
