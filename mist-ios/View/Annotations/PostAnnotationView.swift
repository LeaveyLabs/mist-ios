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

var hasSwipeDemoAnimationRun = false

final class PostAnnotationView: MKMarkerAnnotationView {
    
    static let ReuseID = "Post"
    
    var postCalloutView: PostView? // the postAnnotationView's callout view
    var swipeDemoView: UIView?
    var mapView: MKMapView? {
        var view = superview
        while view != nil {
            if let mapView = view as? MKMapView { return mapView }
            view = view?.superview
        }
        return nil
    }
    
    // Panning gesture
    var panOffset = CGPoint.zero
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
            displayPriority = .required
//            clusteringIdentifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier
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
            if let swipeDemoView = swipeDemoView {
                swipeDemoView.fadeOut(duration: 0.25, delay: 0, completion: { Bool in
                    swipeDemoView.isHidden = true
                    swipeDemoView.removeFromSuperview()
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
}

extension PostAnnotationView {
    
    //MARK: - Public Interface
    
    // Called by the viewController, because the delay differs based on if the post was just uploaded or if it was jut clicked on
    func loadPostView(on mapView: MKMapView,
                      withDelay delay: Double,
                      withPostDelegate postDelegate: ExploreViewController) {
        swipeDelegate = postDelegate

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
        
        //TODO: the fade in should take as long as it takes to fly to the post.
        //the real solution: we want the fly in to be faster if we're super close to the annotation already
        //and we want the values below to depend directly on those values for fly in, not hard coded
        postCalloutView.fadeIn(duration: 0.2, delay: delay - 0.15)
        
        if !hasSwipeDemoAnimationRun {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.runSwipeDemoAnimation()
            }
        }
    }
    
    func runSwipeDemoAnimation() {
        guard let postCalloutView = postCalloutView else { return } //The postCalloutView might have disappeared during that delay
        hasSwipeDemoAnimationRun = true
        displaySwipeDemoInstructions()
                
        UIView.animate(withDuration: 1.5, delay: 0, options: [.curveLinear, .allowUserInteraction, ]) {
            postCalloutView.transform = CGAffineTransform(translationX: 20, y: -5).rotated(by:0.04)
        } completion: { finished in
            UIView.animate(withDuration: 1,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 1,
                           options: [.curveEaseOut, .allowUserInteraction,]) {
                postCalloutView.transform = CGAffineTransform(translationX: 0, y: 0).rotated(by:0)
            }
        }
    }
    
    //put label within a ui view,
    
    func displaySwipeDemoInstructions() {
        swipeDemoView = UIView(frame: .zero)
        guard let postCalloutView = postCalloutView, let swipeDemoView = swipeDemoView else { return }
        swipeDemoView.alpha = 0
        swipeDemoView.backgroundColor = .white
        swipeDemoView.applyMediumShadow()
        swipeDemoView.layer.cornerCurve = .continuous
        swipeDemoView.layer.cornerRadius = 5
        
        self.addSubview(swipeDemoView)
        self.sendSubviewToBack(swipeDemoView)
        swipeDemoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            swipeDemoView.bottomAnchor.constraint(equalTo: postCalloutView.topAnchor, constant: -10),
            swipeDemoView.widthAnchor.constraint(equalTo: postCalloutView.widthAnchor, constant: -70),
            swipeDemoView.heightAnchor.constraint(equalToConstant: 30),
            swipeDemoView.centerXAnchor.constraint(equalTo: postCalloutView.centerXAnchor),
        ])
        
        let swipeDemoInstructionsLabel = UILabel(frame: swipeDemoView.frame)
        swipeDemoInstructionsLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        swipeDemoInstructionsLabel.text = "Swipe to see more mists"
        swipeDemoInstructionsLabel.font = UIFont(name: Constants.Font.Medium, size: 15)
        swipeDemoInstructionsLabel.textColor = .black
        swipeDemoInstructionsLabel.textAlignment = .center
        swipeDemoView.addSubview(swipeDemoInstructionsLabel)
        
        swipeDemoView.fadeIn()
    }
    
    //The callout is currently presented, and we want to update the postView's UI with the new data
    func rerenderCalloutForUpdatedPostData() {
        postCalloutView!.reconfigurePost(updatedPost: (annotation as! PostAnnotation).post)
    }
    
    func movePostUpAfterEmojiKeyboardRaised() {
        layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.constraints.first { $0.firstAnchor == self?.postCalloutView?.bottomAnchor }?.constant = -120
            self?.layoutIfNeeded()
        }
    }
    
    //FUCK sometimes emoji button is just not woriking now...
    
    func movePostBackDownAfterEmojiKeyboardDismissed() {
        layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.constraints.first { $0.firstAnchor == self?.postCalloutView?.bottomAnchor }?.constant = -90
            self?.layoutIfNeeded()
        }
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
        guard let _ = postCalloutView else { return }
        postCalloutView?.layer.removeAllAnimations() //stop the demo if it's in motion
        hasSwipeDemoAnimationRun = true
        switch gestureRecognizer.state {
        case .began:
            break
        case .changed:
            panOffset = gestureRecognizer.translation(in: self)
            incrementSwipe()
            break
        case .ended:
            let didSwipeLeft = panOffset.x < -50
            let didSwipeRight = panOffset.x > 50
            if didSwipeLeft {
                finishSwiping(.left)
            } else if didSwipeRight {
                finishSwiping(.right)
            } else {
                finishSwiping(.incomplete)
            }
            break
        default:
            break
        }
    }
    
    enum SwipeDirection {
        case left, right, incomplete
    }
    
    private func incrementSwipe() {
        guard let postCalloutView = postCalloutView else { return }
        postCalloutView.alpha = 2 - abs(Double(panOffset.x) / 75)
        postCalloutView.transform = CGAffineTransform(translationX: panOffset.x*2, y: min(0, panOffset.y*2))
            .rotated(by: panOffset.x / 300)
    }
    
    private func finishSwiping(_ direction: SwipeDirection) {
        guard let postCalloutView = postCalloutView else { return }
        switch direction {
        case .left:
            swipeDelegate?.handlePostViewSwipeLeft()
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear) {
                postCalloutView.alpha = 0
                postCalloutView.transform = CGAffineTransform(translationX: -400,
                                                              y: self.panOffset.y*4).rotated(by:-0.85)
            } completion: { finished in
                postCalloutView.isHidden = true
            }
        case .right:
            swipeDelegate?.handlePostViewSwipeRight()
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear) {
                postCalloutView.alpha = 0
                postCalloutView.transform = CGAffineTransform(translationX: 400,
                                                              y: self.panOffset.y*4).rotated(by:0.85)
            } completion: { finished in
                postCalloutView.isHidden = true
            }
        case .incomplete:
            UIView.animate(withDuration: 1,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 1,
                           options: .curveEaseOut) {
                postCalloutView.alpha = 1
                postCalloutView.transform = CGAffineTransform(translationX: 0, y: 0).rotated(by:0)
            } completion: { finished in
                
            }
        }
    }
}
