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
    var postView: UIView?

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
        setupMapView()

        allAnnotations = []
        showAllAnnotations(self)
    }
    
    // MARK: - Setup
    
    func setupMapView() {
        centerMapOnUSC()
        registerMapAnnotationViews()
        
        //set iniital pitch
        mapView.camera = MKMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: 4000, pitch: 20, heading: mapView.camera.heading)
        mapView.delegate = self
        
        //        mapView.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: [MKPointOfInterestCategory.cafe, MKPointOfInterestCategory.fitnessCenter, MKPointOfInterestCategory.bakery, MKPointOfInterestCategory.university]))
    }
    
    func centerMapOnUSC() {
        let region = mapView.regionThatFits(MKCoordinateRegion(center: Constants.USC_LAT_LONG, latitudinalMeters: 1200, longitudinalMeters: 1200))
        mapView.setRegion(region, animated: true)
    }
    
    func registerMapAnnotationViews() {
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(BridgeAnnotation.self))
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
    
//    func presentModal(annotation: BridgeAnnotation) {
//        if let mapModal = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.MapModal) as? MapModalViewController {
//            self.mapModal = mapModal
//            mapModal.annotation = annotation
//            if let sheet = mapModal.sheetPresentationController {
//                sheet.detents = [.medium(),]
//                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
//                sheet.prefersGrabberVisible = true
//                sheet.largestUndimmedDetentIdentifier = .medium
//            }
//            present(mapModal, animated: true)
//        }
//    }
}

//https://developer.apple.com/documentation/mapkit/mkmapviewdelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //presentModal(annotation: view.annotation! as! BridgeAnnotation) //not using anymore
                
        //TODO: increase latitudeOffset if the post is really long
        
        loadPostViewFor(annotation: view.annotation! as! BridgeAnnotation)

        let latitudeOffset = 0.0009
//        centerMapUnderPostAt(lat: view.annotation!.coordinate.latitude + latitudeOffset, long: view.annotation!.coordinate.longitude)
//        mapView.isZoomEnabled = false
//        mapView.isScrollEnabled = false
        
        
        //https://stackoverflow.com/questions/21125573/mkmapcamera-pitch-altitude-function
        let pinLocation = CLLocationCoordinate2D(latitude: view.annotation!.coordinate.latitude + latitudeOffset, longitude: view.annotation!.coordinate.longitude)
//        mapView.camera = MKMapCamera(lookingAtCenter: pinLocation, fromDistance: 500, pitch: 0, heading: 0)
        let rotationCamera = MKMapCamera(lookingAtCenter: pinLocation, fromDistance: 500, pitch: 50, heading: mapView.camera.heading)
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.mapView.camera = rotationCamera
        }, completion: nil)
    }
    
    func loadPostViewFor(annotation: BridgeAnnotation) {
        let cell = Bundle.main.loadNibNamed(Constants.SBID.Cell.Post, owner: self, options: nil)?[0] as! PostCell
        if let mapModalPost = annotation.post {
            cell.configurePostCell(post: mapModalPost, parent: self, bubbleArrowPosition: .bottom)
        }
        
        postView = cell.contentView
        if let newPostView = postView {
            newPostView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints
            view.addSubview(newPostView)
            let constraints = [
//                newPostView.topAnchor.constraint(equalTo: dateSliderOuterView.bottomAnchor, constant: 0),
                newPostView.centerYAnchor.constraint(equalTo: mapView.centerYAnchor, constant: -50),
                newPostView.rightAnchor.constraint(equalTo: mapView.rightAnchor, constant: 0),
                newPostView.leftAnchor.constraint(equalTo: mapView.leftAnchor, constant: 0),
            ]
            NSLayoutConstraint.activate(constraints)
            newPostView.alpha = 0
            newPostView.isHidden = true
            
            //TODO: adjust fadeIn time based on how long the fly will take
            newPostView.fadeIn(duration: 0.1, delay: 0.4) { Bool in
                
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        postView?.fadeOut(duration: 0.1, delay: 0, completion: { [self] Bool in
            postView?.isHidden = true
            postView?.removeFromSuperview()
            mapView.isScrollEnabled = true
            mapView.isZoomEnabled = true
        })
    }
        //TODO: on scroll/zoom, deselectannotation and remove postview
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
    }
    
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        print("will start loading")
    }
    
    /// The map view asks `mapView(_:viewFor:)` for an appropiate annotation view for a specific annotation.
    /// - Tag: CreateAnnotationViews
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        guard !annotation.isKind(of: MKUserLocation.self) else {
//            // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
//            return nil
//        }
//        
//        var annotationView: MKAnnotationView?
//        
//        if let annotation = annotation as? BridgeAnnotation {
//            annotationView = setupBridgeAnnotationView(for: annotation, on: mapView)
//        }
//        
//        return annotationView
//    }
    
    /// Create an annotation view for the Golden Gate Bridge, customize the color, and add a button to the callout.
    /// - Tag: CalloutButton
    func setupBridgeAnnotationView(for annotation: BridgeAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        let identifier = NSStringFromClass(BridgeAnnotation.self)
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
        print("out")
        if let markerAnnotationView = view as? MKMarkerAnnotationView {
            print("in")
            //TODO: add constraints to post view
            markerAnnotationView.animatesWhenAdded = true
            markerAnnotationView.canShowCallout = false
            markerAnnotationView.markerTintColor = mistUIColor()
        }
        
        return view
    }
    
    //MARK: -Helpers
    
    func centerMapUnderPostAt(lat: Double, long: Double) {
        let region = mapView.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: long), latitudinalMeters: 200, longitudinalMeters: 200))
        mapView.setRegion(region, animated: true)
    }
}
