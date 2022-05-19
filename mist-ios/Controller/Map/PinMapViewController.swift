//
//  AddMapViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/14.
//

import UIKit
import MapKit

class WildCardGestureRecognizer: UIGestureRecognizer {

    var touchesBeganCallback: ((Set<UITouch>, UIEvent) -> Void)?

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        self.cancelsTouchesInView = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        touchesBeganCallback?(touches, event)
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

typealias PinMapCompletionHandler = ((PostAnnotation, String) -> Void)

class PinMapViewController: MapViewController {

    var completionHandler: PinMapCompletionHandler!
    var pinnedAnnotation: PostAnnotation?
    @IBOutlet weak var topBannerView: UIView!
    
    var pinMapModalVC: PinMapModalViewController?
    
    //TODO: have sheet already be on the map when you click on it. dont even let it bounce up
    
    override func viewDidLoad() {
        super.viewDidLoad()
        latitudeOffset = -0.0007
        applyShadowOnView(topBannerView)
        blurStatusBar()
        handleExistingPin()
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(userInteractedWithMap))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userInteractedWithMap))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userInteractedWithMap))
        mapView.addGestureRecognizer(tapGestureRecognizer)
        mapView.addGestureRecognizer(pinchGestureRecognizer)
        mapView.addGestureRecognizer(panGestureRecognizer)
        
        let tapInterceptor = WildCardGestureRecognizer(target: nil, action: nil)
        tapInterceptor.touchesBeganCallback = {
            _, _ in
        }
//        tapInterceptor.touchesBegan(<#T##touches: Set<UITouch>##Set<UITouch>#>, with: UIEvent())
        mapView.addGestureRecognizer(tapInterceptor)

    }
    
    //MARK: - Setup
    
    func handleExistingPin() {
        if let previousAnnotation = pinnedAnnotation {
            displayedAnnotations = [previousAnnotation]
            mapView.camera = MKMapCamera(
                lookingAtCenter: CLLocationCoordinate2D.init(latitude: previousAnnotation.coordinate.latitude + latitudeOffset,
                                                             longitude: previousAnnotation.coordinate.longitude),
                fromDistance: 500,
                pitch: 50,
                heading: 0)
            presentModal(xsIndentFirst: true)
        }
    }
    
    func blurStatusBar() {
        let blurryEffect = UIBlurEffect(style: .regular)
        let blurredStatusBar = UIVisualEffectView(effect: blurryEffect)
        blurredStatusBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurredStatusBar)
        blurredStatusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        blurredStatusBar.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        blurredStatusBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        blurredStatusBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    }
    
    //MARK: -Navigation
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pinMapModalVC?.dismiss(animated: false)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    //MARK: - User Interaction
    
    @objc func userInteractedWithMap() {
        pinMapModalVC?.toggleSheetSizeTo(sheetSize: "xs")
    }
        
    @IBAction func backButtonDidPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    //TODO: edit this function to make it the proper type of pin
    @IBAction func addAnnotation(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if let mapView = sender.view as? MKMapView {
                let point = sender.location(in: mapView)
                let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
                pinnedAnnotation = PostAnnotation(justWithCoordinate: coordinate)
                displayedAnnotations = [pinnedAnnotation!]
                mapView.selectAnnotation(pinnedAnnotation!, animated: true)
                
                //If a pinMapModal already exists, remove it
                if let pinMapModal = pinMapModalVC {
                    pinMapModal.dismiss(animated: false)
                }
                slowFlyTo(lat: coordinate.latitude + latitudeOffset, long: coordinate.longitude, incrementalZoom: false, completion: {_ in })
                presentModal(xsIndentFirst: false)
            }
        }
    }
    
    override func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        super.mapViewDidChangeVisibleRegion(mapView)
        if !cameraIsMoving {
            pinMapModalVC?.toggleSheetSizeTo(sheetSize: "xs")
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation {
            mapView.deselectAnnotation(view.annotation, animated: false)
            mapView.userLocation.title = "Hey cutie"
        }
        else {
            slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset, long: view.annotation!.coordinate.longitude, incrementalZoom: false, completion: {_ in })
            pinMapModalVC?.toggleSheetSizeTo(sheetSize: "s")
        }
    }
    
    func presentModal(xsIndentFirst: Bool) {
        if let pinMapModalVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.PinMapModal) as? PinMapModalViewController {
            pinMapModalVC.loadViewIfNeeded() //doesnt work without this function call
            pinMapModalVC.sheetDelegate = self
            pinMapModalVC.sheetDismissDelegate = self
            pinMapModalVC.isModalInPresentation = true //prevents the VC from being dismissed by the user
            if xsIndentFirst {
                pinMapModalVC.toggleSheetSizeTo(sheetSize: "xs")
            }
            
            //completion handler returns nil on fail, locationDescription of pin on success
            pinMapModalVC.completionHandler = { [weak self] (locationDescription) in
                if let description = locationDescription {
                    self?.completionHandler((self?.pinnedAnnotation!)!, description)
                    pinMapModalVC.dismiss(animated: false)
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    self?.displayedAnnotations = []
                    self?.dismiss(animated: true)
                }
            }
            self.pinMapModalVC = pinMapModalVC
            present(pinMapModalVC, animated: !xsIndentFirst)
        }
    }
}

extension PinMapViewController: UISheetPresentationControllerDelegate {
    
    // Is not called when sheet is entirely dismissed
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        if sheetPresentationController.selectedDetentIdentifier?.rawValue == "s" {
            if let pinnedAnnotation = pinnedAnnotation {
                slowFlyTo(lat: pinnedAnnotation.coordinate.latitude + latitudeOffset, long: pinnedAnnotation.coordinate.longitude, incrementalZoom: false, completion: {_ in })
                mapView.selectAnnotation(pinnedAnnotation, animated: true)
            }
        }
        else if sheetPresentationController.selectedDetentIdentifier?.rawValue == "xl" {
            pinMapModalVC?.locationDescriptionTextField.becomeFirstResponder()
        }
    }
    
}

extension PinMapViewController: SheetDismissDelegate {
    
    func handleSheetDismiss() {
        for annotation in mapView.annotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }
    
}
