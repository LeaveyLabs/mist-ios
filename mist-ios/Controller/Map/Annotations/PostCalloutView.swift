//
//  PostCalloutView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/03.
//

import UIKit
import MapKit

class PostCalloutView: UIView {
    
    weak var annotation: PostAnnotation?
    
    var contentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()
    
    //MARK: - Init
    
    init(annotation: PostAnnotation) {
        super.init(frame: .zero)
        self.annotation = annotation
        configureView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Should only init programmatically")
    }
    
    //MARK: - Setup
    
    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        
        tintColor = .black
        alpha = 0 // Start hidden by default
        isHidden = true // Start hidden by default
    }
    
    //MARK: - Hit test
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let contentViewPoint = convert(point, to: contentView)
        return contentView.hitTest(contentViewPoint, with: event)
    }

}

// MARK: - Public interface

extension PostCalloutView {
    
    /// Detetcs a touch anywhere in the background of the callout
    /// Does not get called when a touch is registered on a subview with user interaction enabled
    ///
    /// - Parameter sender: The actual hidden button that was tapped, not the callout, itself.

    @objc func didTouchUpInCallout(_ sender: Any) {
        print("did touched up in callout")
    }
    
    func add(toPostAnnotationView postAnnotationView: PostAnnotationView) {
        postAnnotationView.addSubview(self)

        /////////////////TODO: move this up above when possible. it's here for now bc of findViewController() which can only be run after addSubview(self) is run^
        
        let cell = Bundle.main.loadNibNamed(Constants.SBID.Cell.Post, owner: self, options: nil)?[0] as! PostCell
        if let postAnnotation = annotation {
            cell.configurePostCell(post: postAnnotation.post, bubbleTrianglePosition: .bottom)
        }
        contentView = cell.contentView
        addSubview(contentView)
        
        // Make contentView the same size as self
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leftAnchor.constraint(equalTo: leftAnchor),
            contentView.rightAnchor.constraint(equalTo: rightAnchor),
            contentView.widthAnchor.constraint(equalTo: widthAnchor),
            contentView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
        
        // Or, alternatively, instead of extracting from the PostCell.xib,, extract post from PostView.xib
    //        let postViewFromViewNib = Bundle.main.loadNibNamed(Constants.SBID.View.Post, owner: self, options: nil)?[0] as? PostView

        addBackgroundButton(to: contentView) //TODO: this actually shouldnt go on contentview, it should go on the bubbleview. that way the area to l/r of triangle is interactable
        
        //////////////////////////////////asdfasdfasdfasdfasdfasdfasdf

        // constraints for this callout with respect to its superview, postAnnotationView
        
        NSLayoutConstraint.activate([
            contentView.bottomAnchor.constraint(equalTo: postAnnotationView.bottomAnchor, constant: -70),
            contentView.widthAnchor.constraint(equalTo: mapView!.widthAnchor, constant: 0),
            contentView.heightAnchor.constraint(lessThanOrEqualTo: mapView!.heightAnchor, multiplier: 0.60, constant: 0),
            contentView.centerXAnchor.constraint(equalTo: postAnnotationView.centerXAnchor, constant: 0),
        ])
    }

}

private extension PostCalloutView {
    
    /// Add background button to callout
    ///
    /// This adds a button, the same size as the callout's `contentView`, to the `contentView`.
    /// The purpose of this is two-fold: First, it provides an easy method, `didTouchUpInCallout`,
    /// that you can `override` in order to detect taps on the callout. Second, by adding this
    /// button (rather than just adding a tap gesture or the like), it ensures that when you tap
    /// on the button, that it won't simultaneously register as a deselecting of the annotation,
    /// thereby dismissing the callout.
    ///
    /// This serves a similar functional purpose as `_MKSmallCalloutPassthroughButton` in the
    /// default system callout.
    ///
    /// - Parameter view: The view to which we're adding this button.

    func addBackgroundButton(to view: UIView) {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.topAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        button.addTarget(self, action: #selector(didTouchUpInCallout(_:)), for: .touchUpInside)
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
