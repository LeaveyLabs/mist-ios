//
//  AddMapViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/14.
//

import UIKit
import MapKit

typealias PinMapCompletionHandler = ((PostAnnotation, String) -> Void)

class PinMapViewController: MapViewController {

    var pinMapModal: PinMapModalViewController?
    var completionHandler: PinMapCompletionHandler!
    var pinnedAnnotation: PostAnnotation?
    @IBOutlet weak var topBannerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        latitudeOffset = -0.0007
        view.bringSubviewToFront(topBannerView)
        if let previousAnnotation = pinnedAnnotation {
            displayedAnnotations = [previousAnnotation]
        }
        applyShadowOnView(topBannerView)
    }
    
    //MARK: -Navigation
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pinMapModal!.dismiss(animated: false)
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
                if let pinMapModal = pinMapModal {
                    pinMapModal.dismiss(animated: false)
                }
                slowFlyTo(lat: coordinate.latitude + latitudeOffset, long: coordinate.longitude, incrementalZoom: false, completion: {_ in })
                presentModal()
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset, long: view.annotation!.coordinate.longitude, incrementalZoom: false, completion: {_ in })
    }
    
    func presentModal() {

        if let pinMapModalVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.PinMapModal) as? PinMapModalViewController {
            self.pinMapModal = pinMapModalVC
            pinMapModalVC.loadViewIfNeeded() //doesnt work without this function call
            pinMapModalVC.sheetDelegate = self
            pinMapModalVC.sheetDismissDelegate = self
            
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
            present(pinMapModalVC, animated: true)
        }
    }
}

extension PinMapViewController: UISheetPresentationControllerDelegate {
    
    // Is not called when sheet is entirely dismissed
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        print(sheetPresentationController.selectedDetentIdentifier)
    }
    
}

extension PinMapViewController: SheetDismissDelegate {
    
    func handleSheetDismiss() {
        print("DISMISSED")
        print(mapView.annotations)
        for annotation in mapView.annotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }
    
}
