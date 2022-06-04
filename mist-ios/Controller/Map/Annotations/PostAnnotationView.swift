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
    
    var postView: UIView? // the postAnnotationView's callout view
    
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
            self.postView?.removeFromSuperview() // This shouldn't be called, but just in case

            glyphTintColor = mistUIColor() //this is needed bc for some reason the glyph tint color turns grey even with the mist-heart-pink icon
            markerTintColor = mistSecondaryUIColor()
            
//            let postView = ExampleCalloutView(annotation: annotation as! MKShape)
//            postView.add(to: self)
//            self.postView = postView

        } else {
            
            glyphTintColor = .white
            markerTintColor = mistUIColor()
            
            guard let postView = postView else { return }

            postView.fadeOut(duration: 0.5, delay: 0, completion: { Bool in
                postView.isHidden = true
                postView.removeFromSuperview()
            })
        }
    }
    
    // Called by the viewController, because the delay differs based on if the post was just uploaded or if it was jut clicked on
    func loadPostView(withDelay delay: Double) {
        let cell = Bundle.main.loadNibNamed(Constants.SBID.Cell.Post, owner: self, options: nil)?[0] as! PostCell
        if let postAnnotation = annotation as? PostAnnotation {
            cell.configurePostCell(post: postAnnotation.post, parent: findViewController()!, bubbleArrowPosition: .bottom)
        }
        postView = cell.contentView

        // Or, alternatively, instead of extracting from the PostCell.xib,, extract post from PostView.xib
    //        let postViewFromViewNib = Bundle.main.loadNibNamed(Constants.SBID.View.Post, owner: self, options: nil)?[0] as? PostView
        
        if let newPostView = postView {
            newPostView.tintColor = .black
            newPostView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints
            addSubview(newPostView)
            NSLayoutConstraint.activate([
                newPostView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -70),
                newPostView.widthAnchor.constraint(equalTo: mapView!.widthAnchor, constant: 0),
                newPostView.heightAnchor.constraint(lessThanOrEqualTo: mapView!.heightAnchor, multiplier: 0.60, constant: 0),
                newPostView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            ])
            newPostView.alpha = 0
            newPostView.isHidden = true
            newPostView.fadeIn(duration: 0.2, delay: delay-0.15)
        }
    }
    
    // Make sure that if the cell is reused that we remove it from the super view.
    // I think this handles the case where a postView has been rendered for a postannotationview,
    // but then the post annotationview goes offscreen and that same annotationview is reused
    
    override func prepareForReuse() {
        super.prepareForReuse()
        postView?.removeFromSuperview()
    }
    
    // MARK: - Detect taps on callout (postView)

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // If MKMarkerAnnotationView returns non-nil on the hit test, we can just return it
        if let hitAnnotationView = super.hitTest(point, with: event) { return hitAnnotationView }

        // If it wasn't MKMarketerAnnotationView, then the hit view must postView, the the classes's only subview
        if let postView = postView {
            let pointInPostView = convert(point, to: postView)
            return postView.hitTest(pointInPostView, with: event)
        }

        // This should never be reached
        return nil
    }
    
    var mapView: MKMapView? {
        var view = superview
        while view != nil {
            if let mapView = view as? MKMapView { return mapView }
            view = view?.superview
        }
        return nil
    }
}
