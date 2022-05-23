//
//  AddMapViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/14.
//

import UIKit
import MapKit

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

//TODO: when they press "return" from keyboard, call the delegate to transition to "s" size. this transition doesnt automnatically occur if you draw the sheet to the top
//TODO: on exploremap, dont let the filterVC be dismissed if filter is pressed while the map is moving
//TODO: sometimes when you click on the xs size sheet, and it becomes s size, it doesnt highlight the pin

typealias PinMapCompletionHandler = ((PostAnnotation, String) -> Void)

class PinMapViewController: MapViewController {

    var completionHandler: PinMapCompletionHandler!
    var pinnedAnnotation: PostAnnotation?
    @IBOutlet weak var topBannerView: UIView!
    
    var pinMapModalVC: PinMapModalViewController?
        
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
        
//        let tapInterceptor = WildCardGestureRecognizer(target: nil, action: nil)
//        tapInterceptor.touchesBeganCallback = {
//            _, _ in
//        }
//        tapInterceptor.touchesBegan(<#T##touches: Set<UITouch>##Set<UITouch>#>, with: UIEvent())
//        mapView.addGestureRecognizer(tapInterceptor)

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
    
    // This handles the case of tapping, but not panning and dragging for some reason
    @objc func userInteractedWithMap() {
        if (sheetPresentationController?.selectedDetentIdentifier?.rawValue != "xs") {
            //TODO: don't execute this code if you clicked on an existing annotation
            deselectOneAnnotationIfItExists() //annotation will still be deselected without this, but the animation looks better if deselection occurs before togglesheetsisze
            pinMapModalVC?.toggleSheetSizeTo(sheetSize: "xs")
        }
    }
        
    @IBAction func backButtonDidPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addAnnotation(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if let mapView = sender.view as? MKMapView {
                let point = sender.location(in: mapView)
                let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
                pinnedAnnotation = PostAnnotation(justWithCoordinate: coordinate)
                displayedAnnotations = [pinnedAnnotation!]
                
                //TODO: below
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
    
    override func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        super.mapViewDidChangeVisibleRegion(mapView)
        
        // This handles the case of dragging and panning
        if !cameraIsFlying {
            if (sheetPresentationController?.selectedDetentIdentifier?.rawValue != "xs") {
                print(sheetPresentationController?.selectedDetentIdentifier?.rawValue)
                pinMapModalVC?.toggleSheetSizeTo(sheetSize: "xs")
            }
        }
    }
    
    // Could implement later
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("did deselect")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation {
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
        else {
            if sheetPresentationController?.selectedDetentIdentifier?.rawValue != "xl" { // Don't toggle to size s if they manually pulled the sheet all the way up
                pinMapModalVC?.toggleSheetSizeTo(sheetSize: "s")
            }
            slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset, long: view.annotation!.coordinate.longitude, incrementalZoom: false, completion: {_ in })
        }
    }
    
    func presentModal(xsIndentFirst: Bool) {
        if let pinMapModalVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.PinMapModal) as? PinMapModalViewController {
            pinMapModalVC.loadViewIfNeeded() //doesnt work without this function call
            
            pinMapModalVC.sheetDelegate = self //TODO: consolidate these delegates into one or two
            pinMapModalVC.mapDelegate = self
            pinMapModalVC.sheetDismissDelegate = self
            
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
    
    //note: this is only called when the user drags the sheet to a new height. does not get called upon a programmatic change
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        if sheetPresentationController.selectedDetentIdentifier?.rawValue == "s" || sheetPresentationController.selectedDetentIdentifier?.rawValue == "xl" {
            if let pinnedAnnotation = pinnedAnnotation {
                slowFlyTo(lat: pinnedAnnotation.coordinate.latitude + latitudeOffset, long: pinnedAnnotation.coordinate.longitude, incrementalZoom: false, completion: {_ in })
                if sheetPresentationController.selectedDetentIdentifier?.rawValue == "xl" {
                    pinMapModalVC?.locationDescriptionTextField.becomeFirstResponder()
                }
                mapView.selectAnnotation(pinnedAnnotation, animated: true)
            }
        }

        if sheetPresentationController.selectedDetentIdentifier?.rawValue == "xs" {
            deselectOneAnnotationIfItExists()
        }
    }
    
}

extension PinMapViewController: PinMapModalDelegate {
    
    //TODO: this doenst work 100% of the time
    func reselectAnnotation() {
        reselectOneAnnotationIfItExists()
    }
    
}

extension PinMapViewController: childDismissDelegate {
    
    func handleChildWillDismiss() {
        print(mapView.annotations)
        //lol why was i deselecting all annotations here? i already remove the previous annotation when adding the new one, so no need to try and deselect it.
//        deselectAllAnnotations()
    }
    
    func handleChildDidDismiss() {
        
    }
    
}
