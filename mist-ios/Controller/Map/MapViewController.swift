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
    var mapModal: MapModalViewController?

    var allAnnotations: [BridgeAnnotation]?
    
    var displayedAnnotations: [BridgeAnnotation]? {
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

        mapView.delegate = self
        allAnnotations = []
        showAllAnnotations(self)

        mapView.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: []))
    }
    
    func registerMapAnnotationViews() {
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(BridgeAnnotation.self))
    }
    
    // MARK: - Setup
    
    func centerMapOnUSC() {
        let region = mapView.regionThatFits(MKCoordinateRegion(center: Constants.USC_LAT_LONG, latitudinalMeters: 1200, longitudinalMeters: 1200))
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Button Actions
    
    func displayOne(_ annotationType: AnyClass) {
        let annotation = allAnnotations?.first { (annotation) -> Bool in
            return annotation.isKind(of: annotationType)
        }
        
        if let oneAnnotation = annotation {
            displayedAnnotations = [oneAnnotation]
        } else {
            displayedAnnotations = []
        }
    }

    @IBAction func showOnlyBridgeAnnotation(_ sender: Any) {
        // User tapped "Bridge" button in the bottom toolbar
        displayOne(BridgeAnnotation.self)
    }
    
    @IBAction func showAllAnnotations(_ sender: Any) {
        // User tapped "All" button in the bottom toolbar
        displayedAnnotations = allAnnotations
    }
    
    func presentModal(annotation: BridgeAnnotation) {
        if let mapModal = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.MapModal) as? MapModalViewController {
            self.mapModal = mapModal
            mapModal.annotation = annotation
            if let sheet = mapModal.sheetPresentationController {
                sheet.detents = [.medium(),]
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersGrabberVisible = true
                sheet.largestUndimmedDetentIdentifier = .medium
            }
            present(mapModal, animated: true)
        }
    }
}

//https://developer.apple.com/documentation/mapkit/mkmapviewdelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        centerMapAboveModalFor(lat: view.annotation!.coordinate.latitude, long: view.annotation!.coordinate.longitude)
        presentModal(annotation: view.annotation! as! BridgeAnnotation)
    }
    
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        print("will start loading")
    }

    //TODO: this isnt doing anything right now
    /// The map view asks `mapView(_:viewFor:)` for an appropiate annotation view for a specific annotation.
    /// - Tag: CreateAnnotationViews
    func mapView(_ mapView: MKMapView, viewFor annotation: BridgeAnnotation) -> MKAnnotationView? {

        guard !annotation.isKind(of: MKUserLocation.self) else {
            // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
            return nil
        }

        return setupBridgeAnnotationView(for: annotation, on: mapView)
    }
    
    /// Create an annotation view for the Golden Gate Bridge, customize the color, and add a button to the callout.
    /// - Tag: CalloutButton
    func setupBridgeAnnotationView(for annotation: BridgeAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        let identifier = NSStringFromClass(BridgeAnnotation.self)
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
        print("out")
        if let markerAnnotationView = view as? MKMarkerAnnotationView {
            print("in")
            markerAnnotationView.animatesWhenAdded = true
            markerAnnotationView.canShowCallout = true
            markerAnnotationView.markerTintColor = mistUIColor()
            
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
    
    //MARK: -Helpers
    func centerMapAboveModalFor(lat: Double, long: Double) {
        let region = mapView.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat - 0.0007, longitude: long), latitudinalMeters: 200, longitudinalMeters: 200))
        mapView.setRegion(region, animated: true)
    }
}
