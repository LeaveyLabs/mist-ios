//
//  AddMapViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/14.
//

import UIKit
import MapKit
import CoreLocation

protocol PinMapChildDelegate {
    func pinWasMoved(newPin: CLLocationCoordinate2D)
    func pinWasSaved(newPin: CLLocationCoordinate2D)
}

extension UIView {
    
    func roundCornersViaCornerRadius(radius: CGFloat) {
        layer.cornerCurve = .continuous
        layer.cornerRadius = radius
    }
}

class PinMapViewController: MapViewController {
    
    //MARK: - Properties
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var instructionsView: UIView!
    @IBOutlet weak var pinImageView: UIImageView!
    @IBOutlet weak var pinDotView: UIView!
    @IBOutlet weak var pinVerticalConstraint: NSLayoutConstraint!
    let DEFAULT_PIN_OFFSET: CGFloat = -5
    
    func setupUI() {
        pinDotView.layer.cornerCurve = .continuous
        pinDotView.layer.cornerRadius = 5
        
        userTrackingButton.roundCorners(corners: .allCorners, radius: 10)
        pinImageView.roundCornersViaCornerRadius(radius: 10)
        backButton.roundCornersViaCornerRadius(radius: 10)
        backButton.roundCornersViaCornerRadius(radius: 10)
        doneButton.roundCornersViaCornerRadius(radius: 10)
        instructionsView.roundCornersViaCornerRadius(radius: 10)
        
        applyShadowOnView(instructionsView)
        applyShadowOnView(doneButton)
        applyShadowOnView(backButton)
        pinImageView.applyMediumShadow()
    }
    
    var pinMapChildDelegate: PinMapChildDelegate!
    var previousPin: CLLocationCoordinate2D?
    
    //MARK: - Initialization
    
    class func create(existingPin: CLLocationCoordinate2D?, delegate: PinMapChildDelegate) -> PinMapViewController {
        let vc = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.PinMap) as! PinMapViewController
        vc.previousPin = existingPin
        vc.pinMapChildDelegate = delegate
        return vc
    }
            
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        mapViewLegalLabelYOffset = 105
        super.viewDidLoad()
        maxCameraPitch = 0
        setupBlurredStatusBar()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupMapCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.requestUserLocationPermissionIfNecessary()
        }
    }
    
    //MARK: - Setup
    
    func setupMapCamera() {
        var mapCenter: CLLocationCoordinate2D
        if let previousPin = previousPin {
            mapView.camera = MKMapCamera(lookingAtCenter: previousPin, fromDistance: 800, pitch: 0, heading: 0)
        } else if let currentLocation = LocationManager.Shared.currentLocation {
            mapCenter = currentLocation.coordinate
            mapCenter.latitude += 0.0001
            mapView.camera = MKMapCamera(lookingAtCenter: mapCenter, fromDistance: 800, pitch: 0, heading: 0)
        } else {
            mapView.camera = MKMapCamera(lookingAtCenter: Constants.Coordinates.USC, fromDistance: 3500, pitch: 0, heading: 0)
//            let tbc = presentingViewController as! SpecialTabBarController
//            let homeNav =  tbc.viewControllers![0] as! UINavigationController
//            let homeExplore = homeNav.topViewController as! ExploreParentViewController
//            mapCenter = homeExplore.exploreMapVC.mapView.camera.centerCoordinate
        }
    }
    
    func updatePinToMapCenterCoordinate() {
        pinMapChildDelegate.pinWasMoved(newPin: mapView.centerCoordinate)
    }
        
    @IBAction func backButtonDidPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneButtonDidPressed(_ sender: UIButton) {
        pinMapChildDelegate.pinWasSaved(newPin: mapView.centerCoordinate)
        navigationController?.popViewController(animated: true)
    }
    
    //MARK: - MKMapDelegate
    
    //before dragging begins
    override func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        super.mapView(mapView, regionWillChangeAnimated: animated)
        view.layoutIfNeeded()
        doneButton.isEnabled = false
        UIView.animate(withDuration: 0.25) { [self] in
            pinVerticalConstraint.constant = DEFAULT_PIN_OFFSET + 13
            doneButton.alpha = 0.6
            view.layoutIfNeeded()
        }
    }
    
    //continuously throughout dragging
    override func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        super.mapViewDidChangeVisibleRegion(mapView)
    }
    
    //after dragging ends
    override func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        super.mapView(mapView, regionDidChangeAnimated: animated)
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [self] in
            doneButton.alpha = 1
            pinVerticalConstraint.constant = DEFAULT_PIN_OFFSET
            view.layoutIfNeeded()
        }
        pinMapChildDelegate.pinWasMoved(newPin: mapView.centerCoordinate)
        doneButton.isEnabled = true
    }
    
    //MARK: - Public Interface
    
    func renderPlacesOnMap(places: [MKMapItem]) {
        let closestPlaces = Array(places.sorted(by: { first, second in
            mapView.centerCoordinate.distance(from: first.placemark.coordinate) < mapView.centerCoordinate.distance(from: second.placemark.coordinate)
        }).prefix(8))
        print(closestPlaces)
        placeAnnotations = closestPlaces.map({ place in PlaceAnnotation(withPlace: place) })
        removeExistingPlaceAnnotationsFromMap()
        mapView.addAnnotations(placeAnnotations)
        guard let newRegion = getRegionCenteredAround(placeAnnotations.map({ annotation in annotation.coordinate })) else {
            //this shouldnt happen???
//            CustomSwiftMessages.displayError("something went wrong", "")
            return
        }
        if places.count == 1 {
            let moreZoomedRegion = MKCoordinateRegion(center: newRegion.center, span: MKCoordinateSpan(latitudeDelta: newRegion.span.latitudeDelta / 4, longitudeDelta: newRegion.span.longitudeDelta / 4))
            mapView.setRegion(moreZoomedRegion, animated: true)
        } else {
            mapView.setRegion(newRegion, animated: true)
        }
    }
    
}
