//
//  ClusterAnnotationView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/08.
//

import Foundation
import MapKit

class ClusterAnnotationView: MKMarkerAnnotationView {
    
    override var annotation: MKAnnotation? {
        willSet {
            animatesWhenAdded = true
            canShowCallout = false
            markerTintColor = mistUIColor()
            displayPriority = .required
        }
    }
        
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupGestureRecognizerToPreventInteractionDelay()
        centerOffset = CGPoint(x: 0, y: -10) // Offset center point to animate better with marker annotations
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: false)
        print("user selected cluster annotation view!")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        var mapView: MKMapView? {
            var view = superview
            while view != nil {
                if let mapView = view as? MKMapView { return mapView }
                view = view?.superview
            }
            return nil
        }
        mapView?.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            mapView?.isZoomEnabled = true
        }
    }
    
}
