//
//  PostView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/04.
//

import UIKit
import MapKit

@IBDesignable
class PostView: UIView {
        
    //TODO: if you want the the bubble arrow to be clickable, you need to subclass UIButton and override hittest to return true even when the triangle subview is tapped (kinda like tab bar)
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
        //TODO: why does it take half a second for this to be detected?
        print("favorite did pressed")

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
    
    func configurePost(post: Post, bubbleTrianglePosition: BubbleTrianglePosition) {
        self.post = post
        timestampLabel.text = getFormattedTimeString(postTimestamp: post.timestamp)
        locationLabel.text = post.location_description
        messageLabel.text = post.text
        postTitleLabel.text = post.title
        likeLabel.setTitle(String(post.averagerating), for: .normal)
        likeButton.isSelected = false
        favoriteButton.isSelected = false
        
        //adding a pan gesture captures the panning on map and prevents the post from being dismissed
        let pan = UIPanGestureRecognizer()
        pan.delegate = self
        pan.delaysTouchesBegan = false
        pan.delaysTouchesEnded = false
        addGestureRecognizer(UIPanGestureRecognizer())
        
        setupAnnotationQuickSelect()
        
        backgroundBubbleView.transformIntoPostBubble(arrowPosition: bubbleTrianglePosition)
        backgroundBubbleButton.transformIntoPostBubble(arrowPosition: bubbleTrianglePosition)
    }
    
    private func setupAnnotationQuickSelect() {
        let quickSelectGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleMapTapForAnnotationQuickSelect(_:)))
//        quickSelectGestureRecognizer.delaysTouchesBegan = false
//        quickSelectGestureRecognizer.delaysTouchesEnded = false
        quickSelectGestureRecognizer.numberOfTapsRequired = 1
        quickSelectGestureRecognizer.numberOfTouchesRequired = 1
        quickSelectGestureRecognizer.delegate = self
        addGestureRecognizer(quickSelectGestureRecognizer)
    }
    
    // AnnotationQuickSelect: 2 of 3
    @objc func handleMapTapForAnnotationQuickSelect(_ sender: UITapGestureRecognizer? = nil) {
        mapView?.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mapView?.isZoomEnabled = true // in case the tap was not an annotation
        }
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

extension PostView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        mapView?.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mapView?.isZoomEnabled = true // in case the tap was not an annotation
        }
//        return (! [yourButton pointInside:[touch locationInView:yourButton] withEvent:nil]);
        return false
    }
}
