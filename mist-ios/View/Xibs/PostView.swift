//
//  PostView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/04.
//

import UIKit
import MapKit

protocol PostDelegate {
    func likeDidTapped(post: Post)
    func moreDidTapped(post: Post)
    func backgroundDidTapped(post: Post)
    func dmDidTapped(post: Post)
    func commentDidTapped(post: Post)
    func favoriteDidTapped(post: Post)
}

@IBDesignable class PostView: UIView {
        
    @IBOutlet weak var backgroundBubbleButton: UIButton! //in an ideal world we would only use the bubbleButton and not the bubbleView. But alas, you cannot add subviews to uibutton in xibs, yet we need to have the background be a button
    
    @IBOutlet weak var backgroundBubbleView: UIView!
    // Note: When rendered as a callout of PostAnnotationView, in order to prevent touches from being detected on the map, there is a background button which sits at the very back of backgroundBubbleView, with an IBAction hooked up to it. Each view on top of it must either have user interaction disabled so the touches pass back to the button, or they should be a button themselves. Stack views with spacing >0 whose user interaction is enabled will also create undesired behavior where a tap will dismiss the post
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var postTitleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeLabel: UIButton! // In order to prevent the post from dismissing, I either had to a) remove the likeLabel from the stackview and abandon stackview, or b) turn likeLabel into a button which acts as a label. I chose the second option, because stackviews are great.
    
    var postDelegate: PostDelegate?
    var post: Post!
    
    //MARK: - Initialization
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customInit()
    }
    
    private func customInit() {
        guard let contentView = loadViewFromNib(nibName: "PostView") else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
    }
    
    //MARK: - User Interaction
    
    // This action should be detected by a button, because the button will also prevent touches from
    // being passed through to the mapview
    @IBAction func backgroundButtonDidPressed(_ sender: UIButton) {
        postDelegate?.backgroundDidTapped(post: post)
    }
    
    @IBAction func commentButtonDidPressed(_ sender: UIButton) {
        postDelegate?.commentDidTapped(post: post)
    }
    
    @IBAction func dmButtonDidPressed(_ sender: UIButton) {
        postDelegate?.dmDidTapped(post: post)
    }
    
    @IBAction func moreButtonDidPressed(_ sender: UIButton) {
        postDelegate?.moreDidTapped(post: post)
    }
    
    @IBAction func favoriteButtonDidpressed(_ sender: UIButton) {
        // UI Updates
        favoriteButton.isSelected = !favoriteButton.isSelected
        
        postDelegate?.favoriteDidTapped(post: post)
    }
    
    @IBAction func likeButtonDidPressed(_ sender: UIButton) {
        // UI Updates
        let isAlreadyLiked = likeButton.isSelected
        if isAlreadyLiked {
            likeLabel.setTitle(String(Int(likeLabel.titleLabel!.text!)! - 1), for: .normal)
        } else {
            likeLabel.setTitle(String(Int(likeLabel.titleLabel!.text!)! + 1), for: .normal)
        }
        likeButton.isSelected = !likeButton.isSelected
        
        postDelegate?.likeDidTapped(post: post)
    }
    
}

//MARK: - Public Interface

extension PostView {
    
    // Note: the constraints for the PostView should already be set-up when this is called
    func configurePost(post: Post, bubbleTrianglePosition: BubbleTrianglePosition) {
        self.post = post
        timestampLabel.text = getFormattedTimeString(postTimestamp: post.timestamp)
        locationLabel.text = post.location_description
        messageLabel.text = post.text
        postTitleLabel.text = post.title
        likeLabel.setTitle(String(post.averagerating), for: .normal)
        likeButton.isSelected = false
        favoriteButton.isSelected = false
        
        setupGestureRecognizersToPreventMapInteraction()
        backgroundBubbleView.transformIntoPostBubble(arrowPosition: bubbleTrianglePosition)
    }
    
}

// MARK: - Prevent drag / pan on mapView from dismissing post

extension PostView: UIGestureRecognizerDelegate {
    
    var mapView: MKMapView? {
        var view = superview
        while view != nil {
            if let mapView = view as? MKMapView { return mapView }
            view = view?.superview
        }
        return nil
    }
    
    // Add a pan gesture captures the panning on map and prevents the post from being dismissed
    private func setupGestureRecognizersToPreventMapInteraction() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }
    
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        print("handle pan")
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
    
    // If postView is rendered on a mapView, you must turn off isZoomEnabled upon
    // interaction with the postView in order to prevent a 0.5 second delay which occurs on all
    // interaction with post annotation view
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        mapView?.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mapView?.isZoomEnabled = true
        }
        return false
        //return (! [yourButton pointInside:[touch locationInView:yourButton] withEvent:nil]); this code is necessary in case the gesture recognizer is preventing the button press
    }
}
