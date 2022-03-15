//
//  AddMapViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/14.
//

import UIKit
import MapKit

typealias PinMapCompletionHandler = ((MKPointAnnotation, String) -> Void)

class PinMapViewController: MapViewController {

    var pinMapModal: PinMapModalViewController?
    var completionHandler: PinMapCompletionHandler!
    var pinnedAnnotation: MKPointAnnotation?
    @IBOutlet weak var topBannerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.bringSubviewToFront(topBannerView)
        if let previousAnnotation = pinnedAnnotation {
            displayedAnnotations = [previousAnnotation]
        }
    }
    
    //MARK: -Navigation
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pinMapModal?.dismiss(animated: false)
    }
    
    @IBAction func addAnnotation(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if let mapView = sender.view as? MKMapView {
                //if user selects a new location, get rid of the old pin
                if !displayedAnnotations!.isEmpty {
                    displayedAnnotations = []
                }
                let point = sender.location(in: mapView)
                let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
                pinnedAnnotation = MKPointAnnotation()
                pinnedAnnotation!.coordinate = coordinate
                mapView.addAnnotation(pinnedAnnotation!)
                displayedAnnotations?.append(pinnedAnnotation!)
                
                let coordinateAdjustedView = CLLocationCoordinate2D(latitude: coordinate.latitude - 0.00075, longitude: coordinate.longitude)
                let region = mapView.regionThatFits(MKCoordinateRegion(center: coordinateAdjustedView, latitudinalMeters: 200, longitudinalMeters: 200))
                mapView.setRegion(region, animated: true)
                presentModal()
            }
        }
    }
    
    func presentModal() {
        if let pinMapModal = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.PinMapModal) as? PinMapModalViewController {
            self.pinMapModal = pinMapModal
            if let sheet = pinMapModal.sheetPresentationController {
                sheet.detents = [.medium(),]
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersGrabberVisible = true
                sheet.largestUndimmedDetentIdentifier = .medium
            }
                    
            //completion handler returns nil on fail, locationDescription of pin on success
            pinMapModal.completionHandler = { [self] (locationDescription) in
                if let description = locationDescription {
                    completionHandler(pinnedAnnotation!, description)
                    pinMapModal.dismiss(animated: false)
                    navigationController?.popViewController(animated: true)
                } else {
                    displayedAnnotations = []
                    dismiss(animated: true)
                }
            }
            present(pinMapModal, animated: true)
        }
    }
}
