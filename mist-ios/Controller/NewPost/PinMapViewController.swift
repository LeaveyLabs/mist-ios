//
//  AddMapViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/14.
//

import UIKit
import MapKit

typealias PinMapCompletionHandler = ((PostAnnotation?) -> Void)

class PinMapViewController: MapViewController {

    var completionHandler: PinMapCompletionHandler!
    var pinnedAnnotation: PostAnnotation?
    @IBOutlet weak var topBannerView: UIView!
    
    var pinMapModalVC: PinMapModalViewController?
        
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        latitudeOffset = -0.0007
        applyShadowOnView(topBannerView)
        handleExistingPin()
        setMapCameraToExploreCamera()
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(userInteractedWithMap))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userInteractedWithMap))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userInteractedWithMap))
        mapView.addGestureRecognizer(tapGestureRecognizer)
        mapView.addGestureRecognizer(pinchGestureRecognizer)
        mapView.addGestureRecognizer(panGestureRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.requestUserLocationPermissionIfNecessary()
        }
    }
    
    //MARK: - Setup
    
    func setMapCameraToExploreCamera() {
        let tbc = presentingViewController as! SpecialTabBarController
        let homeNav =  tbc.viewControllers![0] as! UINavigationController
        let homeExplore = homeNav.topViewController as! ExploreViewController
        mapView.camera = homeExplore.mapView.camera
    }
    
    func handleExistingPin() {
        if let previousAnnotation = pinnedAnnotation {
            removeExistingPostAnnotationsFromMap()
            postAnnotations = [previousAnnotation]
            mapView.addAnnotations(postAnnotations)
            mapView.camera = MKMapCamera(
                lookingAtCenter: CLLocationCoordinate2D.init(latitude: previousAnnotation.coordinate.latitude + latitudeOffset,
                                                             longitude: previousAnnotation.coordinate.longitude),
                fromDistance: 500,
                pitch: MapViewController.MAX_CAMERA_PITCH,
                heading: 0)
            presentModal(xsIndentFirst: true)
        }
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
    
    // This handles the case of tapping, but not panning and dragging for some reason
    @objc func userInteractedWithMap() {
        if (sheetPresentationController?.selectedDetentIdentifier?.rawValue != "xs") {
            deselectOneAnnotationIfItExists() //annotation will still be deselected without this, but the animation looks better if deselection occurs before togglesheetsisze
            pinMapModalVC?.toggleSheetSizeTo(sheetSize: "xs")
        }
    }
        
    @IBAction func backButtonDidPressed(_ sender: UIButton) {
        //only send the annotation back if it has a title
        if pinnedAnnotation?.title != nil {
            completionHandler(pinnedAnnotation)
        } else {
            pinnedAnnotation = nil
            postAnnotations = []
            removeExistingPostAnnotationsFromMap()
        }
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addAnnotation(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if let mapView = sender.view as? MKMapView {
                let point = sender.location(in: mapView)
                let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
                pinnedAnnotation = PostAnnotation(justWithCoordinate: coordinate)
                removeExistingPostAnnotationsFromMap()
                postAnnotations = [pinnedAnnotation!] //later, when making a unique annotation for pinmap, these previous and later lines could be removed. it's just that not making this process automatic is better for explore
                mapView.addAnnotations(postAnnotations)
                
                //If a pinMapModal already exists... either... (option 1 and 3 are visible in apple maps)
                //1 create a NEW pinMapModal, present it, then dismiss the old one without animation afterwards
                //2 dismiss the old one without animation, present the new one, and deal with a slight delay
                //3 just update the old one and have the view's content reset
                
                //Option 3
//                pinMapModalVC = nil
                //Option 1
                if let pinMapModal = pinMapModalVC {
                    pinMapModal.dismiss(animated: false)
                }
                
                presentModal(xsIndentFirst: false) // Must come BEFORE selecting the annotation
                mapView.selectAnnotation(pinnedAnnotation!, animated: true)
            }
        }
    }
    
    //MARK: - MKMapDelegate
    
    override func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        super.mapViewDidChangeVisibleRegion(mapView)
        
        // This handles the case of dragging and panning
        if !isCameraFlying {
            if (sheetPresentationController?.selectedDetentIdentifier?.rawValue != "xs") {
                pinMapModalVC?.toggleSheetSizeTo(sheetSize: "xs")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation {
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
        else {
            if sheetPresentationController?.selectedDetentIdentifier?.rawValue != "xl" { // Don't toggle to size s if they manually pulled the sheet all the way up
                pinMapModalVC?.toggleSheetSizeTo(sheetSize: "s")
            }
            slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset,
                      long: view.annotation!.coordinate.longitude,
                      incrementalZoom: false,
                      withDuration: cameraAnimationDuration,
                      completion: {_ in })
        }
    }
    
    // Could implement later
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
    }
    
    //MARK: - ModalView
    
    func presentModal(xsIndentFirst: Bool) {
        if let pinMapModalVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.PinMapModal) as? PinMapModalViewController {
            pinMapModalVC.loadViewIfNeeded() //doesnt work without this function call
            
            pinMapModalVC.sheetDelegate = self
            pinMapModalVC.mapDelegate = self
            pinMapModalVC.sheetDismissDelegate = self
            pinMapModalVC.annotation = pinnedAnnotation
            
            if xsIndentFirst {
                pinMapModalVC.toggleSheetSizeTo(sheetSize: "xs")
            }
            
            //completion handler returns nil on fail, locationDescription of pin on success
            pinMapModalVC.completionHandler = { [self] (locationDescription) in
                if locationDescription != nil {
                    completionHandler(pinnedAnnotation)
                    pinMapModalVC.dismiss(animated: false)
                    navigationController?.popViewController(animated: true)
                } else {
                    postAnnotations = []
                    pinnedAnnotation = nil
                    removeExistingPostAnnotationsFromMap()
                    dismiss(animated: true)
                }
            }
            self.pinMapModalVC = pinMapModalVC
            present(pinMapModalVC, animated: !xsIndentFirst)
        }
    }
}

extension PinMapViewController: UISheetPresentationControllerDelegate {
    
    // Note: this is only called when the user drags the sheet to a new height.
    // It does not get called upon a programmatic change in sheet height
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        let sheetID = sheetPresentationController.selectedDetentIdentifier?.rawValue
        
        if sheetID == "s" || sheetID == "xl" {
            guard let pinnedAnnotation = pinnedAnnotation else { return }
            mapView.selectAnnotation(pinnedAnnotation, animated: true)
            if sheetID == "xl" {
                pinMapModalVC?.locationDescriptionTextField.becomeFirstResponder()
            }
        }

        if sheetID == "xs" {
            deselectOneAnnotationIfItExists()
        }
    }
    
}

extension PinMapViewController: PinMapModalDelegate {
    
    func reselectAnnotation() {
        reselectOneAnnotationIfItExists()
    }
    
}

extension PinMapViewController: childDismissDelegate {
    
    func handleChildWillDismiss() {
        //lol why was i deselecting all annotations here? i already remove the previous annotation when adding the new one, so no need to try and deselect it.
//        deselectAllAnnotations()
    }
    
    func handleChildDidDismiss() {
        
    }
    
}



//        let tapInterceptor = WildCardGestureRecognizer(target: nil, action: nil)
//        tapInterceptor.touchesBeganCallback = {
//            _, _ in
//        }
//        tapInterceptor.touchesBegan(<#T##touches: Set<UITouch>##Set<UITouch>#>, with: UIEvent())
//        mapView.addGestureRecognizer(tapInterceptor)

//class WildCardGestureRecognizer: UIGestureRecognizer {
//
//    var touchesBeganCallback: ((Set<UITouch>, UIEvent) -> Void)?
//
//    override init(target: Any?, action: Selector?) {
//        super.init(target: target, action: action)
//        self.cancelsTouchesInView = false
//    }
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
//        super.touchesBegan(touches, with: event)
//        touchesBeganCallback?(touches, event)
//    }
//
//    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return false
//    }
//
//    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return false
//    }
//}
