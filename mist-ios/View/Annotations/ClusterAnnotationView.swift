//
//  ClusterAnnotationView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/08.
//

import Foundation
import MapKit

class ClusterAnnotationView: MKMarkerAnnotationView {
    
    //MARK: - Properties
    
    var mapView: MKMapView? {
        var view = superview
        while view != nil {
            if let mapView = view as? MKMapView { return mapView }
            view = view?.superview
        }
        return nil
    }
    var postCalloutView: PostView? // the postAnnotationView's callout view
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let cluster = newValue as? MKClusterAnnotation else {
                return }
            animatesWhenAdded = true
            canShowCallout = false

            setupMarkerTintColor(cluster.memberAnnotations.count)
            displayPriority = .required
        }
    }
    
    var totalNumberOfAnnotationsRendered: Int {
        return mapView?.annotations.count ?? PostService.singleton.getExplorePostCount()
    }
    
    //MARK: - Initialization
        
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupGestureRecognizerToPreventInteractionDelay()
        setupCarouselView()
        centerOffset = CGPoint(x: 0, y: -10) // Offset center point to animate better with marker annotations
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Setup
    
    func setupCarouselView() {
        
    }
    
    private func setupMarkerTintColor(_ memberCount: Int) {
        let density = Double(memberCount) / Double(totalNumberOfAnnotationsRendered)
        if density < 0.25 {
            markerTintColor = UIColor(hex: "#AE75F7")
        } else if density < 0.5 {
            markerTintColor = Constants.Color.mistPurple
        } else if density < 0.75 {
            markerTintColor = UIColor(hex: "#8D4BE2")
        } else {
            markerTintColor = Constants.Color.mistNight
        }
    }
    
    //MARK: - User Interaction
        
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            guard let postCalloutView = postCalloutView else { return }
            postCalloutView.removeFromSuperview() // This check shouldn't be needed, but just in case
        } else {
            endEditing(true)
            guard let postCalloutView = postCalloutView else { return }
            postCalloutView.fadeOut(duration: 0.25, delay: 0, completion: { Bool in
                postCalloutView.isHidden = true
                postCalloutView.removeFromSuperview()
            })
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitAnnotationView = super.hitTest(point, with: event) {
            return hitAnnotationView
        }

        // If the hit wasn't MKClusterAnnotation, then the hit view must be on the carousel, the the classes's only subview
        if let postView = postCalloutView {
            hasSwipeDemoAnimationRun = true //if they've interacted with the post, turn off the demo
            let pointInPostView = convert(point, to: postView)
            return postView.hitTest(pointInPostView, with: event)
        }

        return nil
    }
    
}

//MARK: - Public Interface

extension ClusterAnnotationView {
    
    func loadPostView(on mapView: MKMapView,
                      withDelay delay: Double,
                      withPostDelegate postDelegate: ExploreViewController) {

        postCalloutView = PostView()
        guard let postCalloutView = postCalloutView else {return}
        
        postCalloutView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(postCalloutView)
        
        NSLayoutConstraint.activate([
            postCalloutView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -90),
            postCalloutView.widthAnchor.constraint(equalTo: mapView.widthAnchor, constant: -50),
            postCalloutView.heightAnchor.constraint(lessThanOrEqualTo: mapView.heightAnchor, multiplier: 0.70, constant: -97),
            postCalloutView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
        ])
        
        let postAnnotation = annotation as! PostAnnotation
        postCalloutView.configurePost(post: postAnnotation.post, delegate: postDelegate)

        //Do i need to call some of these? I dont think so.
        mapView.layoutIfNeeded()
        postCalloutView.setNeedsLayout()
        
        postCalloutView.alpha = 0
        postCalloutView.isHidden = true
        
        postCalloutView.fadeIn(duration: 0.2, delay: 0)
    }
    
    //The callout is currently presented, and we want to update the postView's UI with the new data
    func rerenderCalloutForUpdatedPostData() {
        postCalloutView!.reconfigurePost(updatedPost: (annotation as! PostAnnotation).post)
    }
    
    func movePostUpAfterEmojiKeyboardRaised() {
        layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.constraints.first { $0.firstAnchor == self?.postCalloutView?.bottomAnchor }?.constant = -165
            self?.layoutIfNeeded()
        }
    }
        
    func movePostBackDownAfterEmojiKeyboardDismissed() {
        layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.constraints.first { $0.firstAnchor == self?.postCalloutView?.bottomAnchor }?.constant = -90
            self?.layoutIfNeeded()
        }
    }
}

//MARK: - PreventAnnotationViewInteractionDelay

// Unlike PostAnnotationView, this approach uses a function instead of the GestureRecognizer delegate
// ...I don't THINK there's a difference. Just used a different approach in case one causes an issue later
extension ClusterAnnotationView { //: UIGestureRecognizerDelegate {
    
    // PreventAnnotationViewInteractionDelay: 1 of 2
    // Allows for noticeably faster zooms to the annotationview
    // Turns isZoomEnabled off and on immediately before and after a click on the map.
    // This means that in case the tap happened to be on an annotation, there's less delay.
    // Downside: double tap features are not possible
    //https://stackoverflow.com/questions/35639388/tapping-an-mkannotation-to-select-it-is-really-slow
    private func setupGestureRecognizerToPreventInteractionDelay() {
        let quickSelectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(asdf))
        quickSelectGestureRecognizer.delaysTouchesBegan = false
        quickSelectGestureRecognizer.delaysTouchesEnded = false
        quickSelectGestureRecognizer.numberOfTapsRequired = 1
        quickSelectGestureRecognizer.numberOfTouchesRequired = 1
//        quickSelectGestureRecognizer.delegate = self
        self.addGestureRecognizer(quickSelectGestureRecognizer)
    }
    
    // PreventAnnotationViewInteractionDelay: 2 of 2
    @objc func asdf() {
        mapView?.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.mapView?.isZoomEnabled = true
        }
    }
    
}
