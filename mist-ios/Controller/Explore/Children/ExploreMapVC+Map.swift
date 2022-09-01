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
    
    @IBAction func exploreZoomInButtonDidPressed(_ sender: UIButton) {
        dismissPost()
        zoomInButtonDidPressed(sender)
    }
    
    @IBAction func exploreZoomOutButtonDidPressed(_ sender: UIButton) {
        dismissPost()
        zoomOutButtonDidPressed(sender)
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
        guard let location = locations.last else { return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemark, error) in
            guard error == nil else { return }
            //Here, you can do something on a successful user location update
        }
    }
}

//MARK: - MapDelegate

extension ExploreMapViewController {
        
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
        case .swipe:
            break
//            if let clusterView = view as? ClusterAnnotationView {
//                handleClusterAnnotationSelection(clusterView.annotation as! MKClusterAnnotation, clusterView: clusterView)
//            } else if let postAnnotationView = view as? PostAnnotationView {
//                // - 100 because that's roughly the offset between the middle of the map and the annotaiton
//                let distanceb = postAnnotationView.annotation!.coordinate.distance(from: mapView.centerCoordinate) - 100
//                if distanceb > 400 {
//                    slowFlyOutAndIn(lat: view.annotation!.coordinate.latitude + latitudeOffset,
//                              long: view.annotation!.coordinate.longitude,
//                              withDuration: cameraAnimationDuration,
//                              completion: { _ in })
//                    postAnnotationView.loadPostView(on: mapView,
//                                                    withDelay: cameraAnimationDuration * 4,
//                                                    withPostDelegate: self)
//                } else {
//                    slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset,
//                              long: view.annotation!.coordinate.longitude,
//                              incrementalZoom: false,
//                              withDuration: cameraAnimationDuration,
//                              completion: { _ in })
//                    postAnnotationView.loadPostView(on: mapView,
//                                                    withDelay: cameraAnimationDuration,
//                                                    withPostDelegate: self)
//                }
//            }
        case .submission:
            if let clusterView = view as? ClusterAnnotationView {
                handleClusterAnnotationSelection(clusterView.annotation as! MKClusterAnnotation, clusterView: clusterView)
            } else if let postAnnotationView = view as? PostAnnotationView {
                postAnnotationView.loadPostView(on: mapView,
                                                withDelay: 0,
                                                withPostDelegate: postDelegate)
            }
        default:
            if let clusterView = view as? ClusterAnnotationView {
                handleClusterAnnotationSelection(clusterView.annotation as! MKClusterAnnotation, clusterView: clusterView)
            } else if let postAnnotationView = view as? PostAnnotationView {
                let shouldZoomIn = mapView.camera.centerCoordinateDistance > MapViewController.ANNOTATION_ZOOM_THRESHOLD
                if shouldZoomIn {
                    slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset,
                              long: view.annotation!.coordinate.longitude,
                              incrementalZoom: false,
                              withDuration: cameraAnimationDuration,
                              completion: { _ in })
                    postAnnotationView.loadPostView(on: mapView,
                                                    withDelay: cameraAnimationDuration,
                                                    withPostDelegate: postDelegate)
                } else {
                    slowFlyWithoutZoomTo(lat: view.annotation!.coordinate.latitude,
                                         long: view.annotation!.coordinate.longitude,
                              withDuration: cameraAnimationDuration,
                              completion: { _ in })
                    postAnnotationView.loadPostView(on: mapView,
                                                    withDelay: cameraAnimationDuration,
                                                    withPostDelegate: postDelegate)
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
    
    // I believe this code is outdated
//    func mapAnnotationDidTouched(_ sender: UIButton) {
//        let filterMapModalVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.SortBy) as! SortByViewController
//        if let sheet = filterMapModalVC.sheetPresentationController {
//            sheet.detents = [.medium()]
//            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
//            sheet.prefersGrabberVisible = true
//            sheet.largestUndimmedDetentIdentifier = .medium
//        }
//        present(filterMapModalVC, animated: true, completion: nil)
//    }
     
    // This could be useful for managing cluster behavior
//    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
//
//    }
    
    //MARK: Map Helpers
    
    func dismissPost() {
        deselectOneAnnotationIfItExists()
    }
    
    func renderNewPlacesOnMap() {
        removeExistingPlaceAnnotationsFromMap()
        mapView.region = getRegionCenteredAround(placeAnnotations) ?? PostService.singleton.getExploreFilter().region
        mapView.addAnnotations(placeAnnotations)
    }
    
    func handleClusterAnnotationSelection(_ clusterAnnotation: MKClusterAnnotation, clusterView: ClusterAnnotationView) {
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
                      withDuration: cameraAnimationDuration,
                      completion: { [weak self] completed in
                guard let self = self else { return }
//                let doesClusterStillExist = self.mapView.selectedAnnotations.contains { annotation in
//                    annotation as? MKClusterAnnotation == clusterAnnotation
//                }
//                guard doesClusterStillExist else { return }
                clusterView.loadCollectionView(on: self.mapView, withPostDelegate: self.postDelegate)
            })
        }
    }
    
}


//MARK: Post swiping

extension ExploreMapViewController: AnnotationViewSwipeDelegate {

    func handlePostViewSwipeRight() {
//        guard var index = selectedAnnotationIndex else { return }
//
//        let selectedAnnotationView = selectedAnnotationView as! PostAnnotationView
//        mapView.deselectAnnotation(selectedAnnotationView.annotation, animated: true)
//        index += 1
//        if index == postAnnotations.count {
//            index = 0
//        }
//        let nextAnnotation = postAnnotations[index]
//        annotationSelectionType = .swipe
//        mapView.selectAnnotation(nextAnnotation, animated: true)
    }
//    
    func handlePostViewSwipeLeft() {
//        guard var index = selectedAnnotationIndex else { return }
//        
//        //        let postView = pav.postCalloutView!
//        //        postView.animation = "slideLeft"
//        //        postView.duration = 2
//        //        postView.rever
//        
//        let selectedAnnotationView = selectedAnnotationView as! PostAnnotationView
//        mapView.deselectAnnotation(selectedAnnotationView.annotation, animated: true)
//        index -= 1
//        if index == -1 {
//            index = postAnnotations.count-1
//        }
//        let nextAnnotation = postAnnotations[index]
//        annotationSelectionType = .swipe
//        mapView.selectAnnotation(nextAnnotation, animated: true)
    }
    
}
