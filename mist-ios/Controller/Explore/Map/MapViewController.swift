//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var allAnnotations: [MKAnnotation]?
    
    var displayedAnnotations: [MKAnnotation]? {
        willSet {
            if let currentAnnotations = displayedAnnotations {
                mapView.removeAnnotations(currentAnnotations)
            }
        }
        didSet {
            if let newAnnotations = displayedAnnotations {
                mapView.addAnnotations(newAnnotations)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.restoreHairline()
        centerMapOnUSC()
        registerMapAnnotationViews()
        //let customAnnotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: 34.0204, longitude: -118.2861))
//        customAnnotation.title = "Omg this guy named kevin in my history class"

//        allAnnotations = [BridgeAnnotation()]
        allAnnotations = []
        showAllAnnotations(self)

        mapView.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: []))
    }
    
    private func registerMapAnnotationViews() {
        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(CustomAnnotation.self))
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(BridgeAnnotation.self))
    }
    
    // MARK: - Setup
    
    private func centerMapOnUSC() {
        let coordinate = CLLocationCoordinate2D(latitude: 34.0184, longitude: -118.2861)
        let region = mapView.regionThatFits(MKCoordinateRegion(center: coordinate, latitudinalMeters: 1200, longitudinalMeters: 1200))
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Button Actions
    
    private func displayOne(_ annotationType: AnyClass) {
        let annotation = allAnnotations?.first { (annotation) -> Bool in
            return annotation.isKind(of: annotationType)
        }
        
        if let oneAnnotation = annotation {
            displayedAnnotations = [oneAnnotation]
        } else {
            displayedAnnotations = []
        }
    }

    @IBAction private func showOnlyBridgeAnnotation(_ sender: Any) {
        // User tapped "Bridge" button in the bottom toolbar
        displayOne(BridgeAnnotation.self)
    }
    
    @IBAction private func showOnlyFlowerAnnotation(_ sender: Any) {
        // User tapped "Flower" button in the bottom toolbar
        displayOne(CustomAnnotation.self)
    }
    
    @IBAction private func showAllAnnotations(_ sender: Any) {
        // User tapped "All" button in the bottom toolbar
        displayedAnnotations = allAnnotations
    }
}

extension MapViewController: MKMapViewDelegate {

    /// Called whent he user taps the disclosure button in the bridge callout.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        // This illustrates how to detect which annotation type was tapped on for its callout.
        if let annotation = view.annotation, annotation.isKind(of: BridgeAnnotation.self) {
            print("Tapped Golden Gate Bridge annotation accessory view")
            
            if let detailNavController = storyboard?.instantiateViewController(withIdentifier: "DetailNavController") {
                detailNavController.modalPresentationStyle = .popover
                let presentationController = detailNavController.popoverPresentationController
                presentationController?.permittedArrowDirections = .any
                
                // Anchor the popover to the button that triggered the popover.
                presentationController?.sourceRect = control.frame
                presentationController?.sourceView = control
                
                present(detailNavController, animated: true, completion: nil)
            }
        }
    }
    
    /// The map view asks `mapView(_:viewFor:)` for an appropiate annotation view for a specific annotation.
    /// - Tag: CreateAnnotationViews
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !annotation.isKind(of: MKUserLocation.self) else {
            // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
            return nil
        }
        
        var annotationView: MKAnnotationView?
        
        if let annotation = annotation as? BridgeAnnotation {
            annotationView = setupBridgeAnnotationView(for: annotation, on: mapView)
        } else if let annotation = annotation as? CustomAnnotation {
            annotationView = setupCustomAnnotationView(for: annotation, on: mapView)
        }
        
        return annotationView
    }
    
    /// Create an annotation view for the Golden Gate Bridge, customize the color, and add a button to the callout.
    /// - Tag: CalloutButton
    private func setupBridgeAnnotationView(for annotation: BridgeAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        let identifier = NSStringFromClass(BridgeAnnotation.self)
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
        if let markerAnnotationView = view as? MKMarkerAnnotationView {
            markerAnnotationView.animatesWhenAdded = true
            markerAnnotationView.canShowCallout = true
            markerAnnotationView.markerTintColor = UIColor(named: "internationalOrange")
            
            /*
             Add a detail disclosure button to the callout, which will open a new view controller or a popover.
             When the detail disclosure button is tapped, use mapView(_:annotationView:calloutAccessoryControlTapped:)
             to determine which annotation was tapped.
             If you need to handle additional UIControl events, such as `.touchUpOutside`, you can call
             `addTarget(_:action:for:)` on the button to add those events.
             */
            let rightButton = UIButton(type: .detailDisclosure)
            markerAnnotationView.rightCalloutAccessoryView = rightButton
        }
        
        return view
    }
    
    private func setupCustomAnnotationView(for annotation: CustomAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        return mapView.dequeueReusableAnnotationView(withIdentifier: NSStringFromClass(CustomAnnotation.self), for: annotation)
    }
}
