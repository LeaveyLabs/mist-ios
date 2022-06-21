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

extension ExploreViewController {
    
    @IBAction func exploreUserTrackingButtonDidPressed(_ sender: UIButton) {
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

extension ExploreViewController {
    
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

extension ExploreViewController {
        
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation {
            mapView.deselectAnnotation(view.annotation, animated: false)
            mapView.userLocation.title = "Hey cutie"
        }
        
        selectedAnnotationView = view
        mapView.isZoomEnabled = true // AnnotationQuickSelect: 3 of 3, just in case
        switch annotationSelectionType {
        case .swipe:
            if let clusterAnnotation = view.cluster?.annotation as? MKClusterAnnotation {
                mapView.deselectAnnotation(view.annotation, animated: false)
                handleClusterAnnotationSelection(clusterAnnotation)
            } else if let postAnnotationView = view as? PostAnnotationView {
                // - 100 because that's roughly the offset between the middle of the map and the annotaiton
                let distanceb = postAnnotationView.annotation!.coordinate.distance(from: mapView.centerCoordinate) - 100
                if distanceb > 400 {
                    slowFlyOutAndIn(lat: view.annotation!.coordinate.latitude + latitudeOffset,
                              long: view.annotation!.coordinate.longitude,
                              withDuration: cameraAnimationDuration,
                              completion: { _ in })
                    postAnnotationView.loadPostView(on: mapView,
                                                    withDelay: cameraAnimationDuration * 4,
                                                    withPostDelegate: self)
                } else {
                    slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset,
                              long: view.annotation!.coordinate.longitude,
                              incrementalZoom: false,
                              withDuration: cameraAnimationDuration,
                              completion: { _ in })
                    postAnnotationView.loadPostView(on: mapView,
                                                    withDelay: cameraAnimationDuration,
                                                    withPostDelegate: self)
                }
            }
        case .submission:
            if let clusterAnnotation = view.cluster?.annotation as? MKClusterAnnotation {
                mapView.deselectAnnotation(view.annotation, animated: false)
                handleClusterAnnotationSelection(clusterAnnotation)
            } else if let postAnnotationView = view as? PostAnnotationView {
                postAnnotationView.loadPostView(on: mapView,
                                                withDelay: 0,
                                                withPostDelegate: self)
            }
        default:
            if let clusterAnnotation = view.annotation as? MKClusterAnnotation {
                mapView.deselectAnnotation(view.annotation, animated: false)
                handleClusterAnnotationSelection(clusterAnnotation)
            } else if let postAnnotationView = view as? PostAnnotationView {
                slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset,
                          long: view.annotation!.coordinate.longitude,
                          incrementalZoom: false,
                          withDuration: cameraAnimationDuration,
                          completion: { _ in })
                postAnnotationView.loadPostView(on: mapView,
                                                withDelay: cameraAnimationDuration,
                                                withPostDelegate: self)
            } else if let placeAnnotationView = view as? PlaceAnnotationView {
                mapView.deselectAnnotation(placeAnnotationView.annotation, animated: false)
            }
        }
        annotationSelectionType = .normal // Return to default
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        //shouldnt actually be necessary, because we're doing a localDataUpdate on each user interaction with a postView
//        if let deselectedPostAnnotationView = selectedAnnotationView as? PostAnnotationView {
//            localDataUpdateForEntirePost(deselectedPostAnnotationView.postCalloutView!.post)
//            selectedAnnotationView = nil
//        }
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
    
    // To make the map fly directly to the middle of cluster locations...
    // After loading the annotations for the map, immediately center the camera around the annotation
    // (as if it had flown there), check if it's an annotation, then set the camera back to USC
    func handleNewlySubmittedPost(_ newPost: Post) {
        annotationSelectionType = .submission
        if let newPostIndex = postAnnotations.firstIndex(where: { postAnnotation in
            postAnnotation.post == newPost
        }) {
            postAnnotations.insert(postAnnotations.remove(at: newPostIndex), at: 0) //put user submitted post first
            feed.reloadData() //need to reload data after rearranging posts
            feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            let newPostAnnotation = postAnnotations.first!
            slowFlyTo(lat: newPostAnnotation.coordinate.latitude + latitudeOffset,
                      long: newPostAnnotation.coordinate.longitude,
                      incrementalZoom: false,
                      withDuration: cameraAnimationDuration+2,
                      completion: { [self] _ in
                mapView.selectAnnotation(newPostAnnotation, animated: true)
            })
        }
    }
    
    func handleClusterAnnotationSelection(_ clusterAnnotation: MKClusterAnnotation) {
        let wasHotspotBeforeSlowFly = clusterAnnotation.isHotspot
        slowFlyTo(lat: clusterAnnotation.coordinate.latitude,
                  long: clusterAnnotation.coordinate.longitude,
                  incrementalZoom: true,
                  withDuration: cameraAnimationDuration,
                  completion: { _ in
            if wasHotspotBeforeSlowFly {
                var posts = [Post]()
                for annotation in clusterAnnotation.memberAnnotations {
                    if let annotation = annotation as? PostAnnotation {
                        posts.append(annotation.post)
                    }
                }
                let newVC = SearchResultsTableViewController.resultsFeedViewController(feedType: .hotspot, feedValue: clusterAnnotation.title!)
                newVC.posts = posts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.navigationController?.pushViewController(newVC, animated: true)
                }
            } else {

            }
        })
    }
    
}


//MARK: Post swiping

extension ExploreViewController: AnnotationViewSwipeDelegate {

    func handlePostViewSwipeRight() {
        guard var index = selectedAnnotationIndex else { return }

        let selectedAnnotationView = selectedAnnotationView as! PostAnnotationView
        mapView.deselectAnnotation(selectedAnnotationView.annotation, animated: true)
        index += 1
        if index == postAnnotations.count {
            index = 0
        }
        let nextAnnotation = postAnnotations[index]
        annotationSelectionType = .swipe
        mapView.selectAnnotation(nextAnnotation, animated: true)
    }
    
    func handlePostViewSwipeLeft() {
        guard var index = selectedAnnotationIndex else { return }
        
        //        let postView = pav.postCalloutView!
        //        postView.animation = "slideLeft"
        //        postView.duration = 2
        //        postView.rever
        
        let selectedAnnotationView = selectedAnnotationView as! PostAnnotationView
        mapView.deselectAnnotation(selectedAnnotationView.annotation, animated: true)
        index -= 1
        if index == -1 {
            index = postAnnotations.count-1
        }
        let nextAnnotation = postAnnotations[index]
        annotationSelectionType = .swipe
        mapView.selectAnnotation(nextAnnotation, animated: true)
    }
    
}
