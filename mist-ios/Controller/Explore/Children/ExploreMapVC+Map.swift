//
//  ExploreViewController+Map.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/11.
//

import Foundation
import UIKit
import MapKit

//MARK: - Map

//MARK: - Map Interaction

class MyMapView: MKMapView {
    
    
}

extension ExploreMapViewController {
    
    //MARK: - Setup
    
    func setupExploreMapButtons() {
        searchButton.roundCorners(corners: [.topLeft, .bottomLeft, .topRight, .bottomRight], radius: 10)
        filterButton.roundCorners(corners: [.topRight, .bottomRight], radius: 10)
        applyShadowOnView(exploreButtonStackView)
    }
    
    //MARK: - User Interaction
    
    @IBAction func searchButtonPressed(_ sender: UIButton) {
        presentExploreSearchController()
    }
    
    @IBAction func exploreUserTrackingButtonPressed(_ sender: UIButton) {
        dismissPost()
        userTrackingButtonDidPressed(sender)
    }
    
    @IBAction func exploreMapDimensionButtonDidPressed(_ sender: UIButton) {
        dismissPost()
        mapDimensionButtonDidPressed(sender)
    }
    
    //MARK: AnnotationViewInteractionDelayPrevention

    // Allows for noticeably faster zooms to the annotationview
    // Turns isZoomEnabled off and on immediately before and after a click on the map.
    // This means that in case the tap happened to be on an annotation, there's less delay.
    // Downside: double tap features are not possible
    //https://stackoverflow.com/questions/35639388/tapping-an-mkannotation-to-select-it-is-really-slow
    // Note: even though it would make the most sense for the tap gesture to live on the annotationView,
    // when that's the case, some clicks NEAR but not ON the annotation view result in a delay.
    // We want 0 delays, so we're putting it on the mapView
        
    func setupCustomTapGestureRecognizerOnMap() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.delaysTouchesBegan = false
        tapRecognizer.delaysTouchesEnded = false
        mapView.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        // AnnotationViewInteractionDelayPrevention 1 of 2
        mapView.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.mapView.isZoomEnabled = true
        }
        
        // Handle other purposes of the tap gesture besides just AnnotationViewInteractionDelayPrevention:
        deselectOneAnnotationIfItExists()
    }
    
}

// MARK: - CLLocationManagerDelegate

extension ExploreMapViewController {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else { return }
        
//        let geocoder = CLGeocoder()
//        geocoder.reverseGeocodeLocation(location) { (placemark, error) in
//            guard error == nil else { return }
//            //Here, you can do something on a successful user location update
//        }
    }
}

//MARK: - MapDelegate

extension ExploreMapViewController {
        
//    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
//        if memberAnnotations.contains(where: { $0.coordinate == (selectedAnnotationView as? MKAnnotation)?.coordinate }) {
//            deselectOneAnnotationIfItExists()
//        }
//        return MKClusterAnnotation(memberAnnotations: memberAnnotations)
//    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation {
            mapView.deselectAnnotation(view.annotation, animated: false)
            slowFlyTo(lat: view.annotation!.coordinate.latitude,
                      long: view.annotation!.coordinate.longitude,
                      incrementalZoom: false,
                      withDuration: cameraAnimationDuration,
                      completion: { _ in })
        }
        selectedAnnotationView = view as? AnnotationViewWithPosts
        mapView.isZoomEnabled = true // AnnotationQuickSelect: 3 of 3, just in case
        switch annotationSelectionType {
        case .submission:
            if let clusterView = view as? ClusterAnnotationView { //slow fly again after slow flying originally, because the clusterView could be offset from the post within the cluster, adn we want the cluster to be centered
                slowFlyWithoutZoomTo(lat: clusterView.annotation!.coordinate.latitude,
                                     long: clusterView.annotation!.coordinate.longitude,
                                      withDuration: cameraAnimationDuration,
                                     withLatitudeOffset: true,
                                      completion: { [weak self] completed in
                    guard let self = self else { return }
                    clusterView.loadCollectionView(on: self.mapView, withPostDelegate: self.postDelegate)
                })
            } else if let postAnnotationView = view as? PostAnnotationView {
                postAnnotationView.loadPostView(on: mapView,
                                                withDelay: 0,
                                                withPostDelegate: postDelegate)
            }
        case .swipe: //just slow fly, since the collectionView is already visible
            
            //WAIT WHAT
            //how could a newly selected annotationView not have an annotation?
            
            slowFlyWithoutZoomTo(lat: view.annotation!.coordinate.latitude, long: view.annotation!.coordinate.longitude, withDuration: cameraAnimationDuration, withLatitudeOffset: true)
        default: //aka a tap
                //if we're close enough, slow fly AND render the collectionView
                //if we're too far out, simply zoom in
            if let clusterView = view as? ClusterAnnotationView,
                let clusterAnnotation = clusterView.annotation {
                let shouldZoomIn = mapView.camera.centerCoordinateDistance > MapViewController.ANNOTATION_ZOOM_THRESHOLD
                if shouldZoomIn {
                    mapView.deselectAnnotation(clusterAnnotation, animated: false)
                    slowFlyTo(lat: clusterAnnotation.coordinate.latitude,
                              long: clusterAnnotation.coordinate.longitude,
                              incrementalZoom: true,
                              withDuration: cameraAnimationDuration,
                              completion: {_ in } )
                } else {
                    slowFlyWithoutZoomTo(lat: clusterAnnotation.coordinate.latitude,
                              long: clusterAnnotation.coordinate.longitude,
                              withDuration: cameraAnimationDuration, withLatitudeOffset: true,
                              completion: { [weak self] completed in
                        guard let self = self else { return }
        //                let doesClusterStillExist = self.mapView.selectedAnnotations.contains { annotation in
        //                    annotation as? MKClusterAnnotation == clusterAnnotation
        //                }
        //                guard doesClusterStillExist else { return }
                        self.toggleCollectionView(shouldBeHidden: false)
                    })
                }
            } else if let _ = view as? PostAnnotationView {
                let shouldZoomIn = mapView.camera.centerCoordinateDistance > MapViewController.ANNOTATION_ZOOM_THRESHOLD
                if shouldZoomIn {
                    slowFlyTo(lat: view.annotation!.coordinate.latitude,
                              long: view.annotation!.coordinate.longitude,
                              incrementalZoom: false,
                              withDuration: cameraAnimationDuration,
                              withLatitudeOffset: true,
                              completion: { completed in
                        self.toggleCollectionView(shouldBeHidden: false)
                    })
                } else {
                    slowFlyWithoutZoomTo(lat: view.annotation!.coordinate.latitude,
                                         long: view.annotation!.coordinate.longitude,
                              withDuration: cameraAnimationDuration, withLatitudeOffset: true,
                              completion: { _ in
                        self.toggleCollectionView(shouldBeHidden: false)
                    })
                    
                }
            } else if let _ = view as? PlaceAnnotationView {
                slowFlyTo(lat: view.annotation!.coordinate.latitude,
                          long: view.annotation!.coordinate.longitude,
                          incrementalZoom: false,
                          withDuration: cameraAnimationDuration * 2,
                          completion: { _ in })
            }
        }
        annotationSelectionType = .normal // Return to default
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        selectedAnnotationView = nil
//        toggleCollectionView(shouldBeHidden: true)
    }
    
    override func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        super.mapView(mapView, regionDidChangeAnimated: animated)
        if selectedAnnotationView != nil {
            zoomSliderGradientImageView.layer.removeAllAnimations()
            self.zoomSliderGradientImageView.alpha = 0
        }
    }
    
    override func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        super.mapViewDidChangeVisibleRegion(mapView)
        
        //If you want to dismiss on drag/pan, then fix this code
//        if !cameraIsFlying {
//            print(sheetPresentationController?.selectedDetentIdentifier)
//            if sheetPresentationController?.selectedDetentIdentifier != nil && sheetPresentationController?.selectedDetentIdentifier?.rawValue != "zil" {
//                dismissFilter()
//            }
//        }
    }
    
    //MARK: Map Helpers
    
    func dismissPost() {
        deselectOneAnnotationIfItExists()
    }
    
    func renderNewPlacesOnMap() {
        removeExistingPlaceAnnotationsFromMap()
        mapView.setRegion(getRegionCenteredAround(placeAnnotations) ?? PostService.singleton.getExploreFilter().region, animated: true)
        mapView.addAnnotations(placeAnnotations)
    }
    
}
