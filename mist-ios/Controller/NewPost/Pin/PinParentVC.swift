//
//  NewPostPinParent.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/3/22.
//

import Foundation
import OverlayContainer
import UIKit
import CoreLocation
import MapKit

typealias PinMapCompletionHandler = ((CLLocationCoordinate2D?) -> Void)

class PinParentViewController: UIViewController {
    
    enum OverlayNotch: Int, CaseIterable {
        case minimum, maximum
    }

    //MARK: - Properties
    
    //Overlay
    @IBOutlet var overlayContainerView: UIView!
    @IBOutlet var backgroundView: UIView!
    var pinMapVC: PinMapViewController!
    var pinSearchVC: PinSearchViewController!
    var overlayController = OverlayContainerViewController()
    var currentNotch: OverlayNotch = .minimum
    
    var pin: CLLocationCoordinate2D?
    var completionHandler: PinMapCompletionHandler!
    
    //MARK: - Initialization
    
    class func create(currentPin: CLLocationCoordinate2D?, completionHandler: @escaping PinMapCompletionHandler) -> PinParentViewController {
        let vc = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.PinParent) as! PinParentViewController
        vc.pin = currentPin
        vc.completionHandler = completionHandler
        return vc
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOverlay()
        overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: false, completion: nil)
    }
}

extension PinParentViewController: PinMapChildDelegate {
    
    func pinWasSaved(newPin: CLLocationCoordinate2D) {
        pin = newPin
        completionHandler(pin)
    }
    
    func pinWasMoved(newPin: CLLocationCoordinate2D) {
        pinSearchVC.startProvidingCompletions(around: newPin)
    }
    
}

extension PinParentViewController: PinSearchChildDelegate {
    
    func searchResultsUpdated(newResults: [MKMapItem]) {
        overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: true, completion: nil)
        pinMapVC.renderPlacesOnMap(places: newResults)
    }
    
    func shouldGoUp() {
        overlayController.moveOverlay(toNotchAt: OverlayNotch.maximum.rawValue, animated: true, completion: nil)
    }
    
    func shouldGoDown() {
        overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: true, completion: nil)
    }
    
}

// MARK: - OverlayContainer

extension PinParentViewController: OverlayContainerViewControllerDelegate {
    
    func setupOverlay() {
        overlayController.delegate = self
        pinMapVC = PinMapViewController.create(existingPin: pin, delegate: self)
        pinSearchVC = PinSearchViewController.create(delegate: self)
        pinSearchVC.startProvidingCompletions(around: pin)
        overlayController.viewControllers = [pinSearchVC]
        addChild(pinMapVC, in: backgroundView)
        addChild(overlayController, in: overlayContainerView)
        let notchTap = UITapGestureRecognizer(target: self, action: #selector(didTapFeedNotch))
        pinSearchVC.notchView.addGestureRecognizer(notchTap)
    }
    
    private func notchHeight(for notch: OverlayNotch, availableSpace: CGFloat) -> CGFloat {
        switch notch {
        case .maximum:
            return availableSpace * 0.99
        case .minimum:
            return 85
        }
    }
        
    @objc func didTapFeedNotch() {
        switch currentNotch {
        case .minimum:
            pinSearchVC.searchBar.becomeFirstResponder()
            overlayController.moveOverlay(toNotchAt: OverlayNotch.maximum.rawValue, animated: true, completion: nil)
        case .maximum:
            pinSearchVC.searchBar.resignFirstResponder()
            overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: true, completion: nil)
        }
    }
    
    func numberOfNotches(in containerViewController: OverlayContainerViewController) -> Int {
        return OverlayNotch.allCases.count
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        heightForNotchAt index: Int,
                                        availableSpace: CGFloat) -> CGFloat {
        let notch = OverlayNotch.allCases[index]
        return notchHeight(for: notch, availableSpace: availableSpace)
    }
    
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, willMoveOverlay overlayViewController: UIViewController, toNotchAt index: Int) {
        guard
            let notch = OverlayNotch.init(rawValue: index)
        else { return }
        //We can't simply do a switch, because we don't want to cause the "view.layoutIfNeeded" animation on the VC's first appearance, when currentNotch = .minimum and newNotch = .minimum
        if (currentNotch == .minimum || currentNotch == .maximum) && notch == .maximum {
            pinSearchVC.searchBar.becomeFirstResponder()
            UIView.animate(withDuration: 0.25, delay: 0) {
                self.pinSearchVC.searchBarHeightConstraint.constant = 43
                self.pinSearchVC.searchBarDividerUIView.alpha = 1
                self.pinSearchVC.view.layoutIfNeeded()
                self.pinMapVC.removeBlurredStatusBar()
            }
        } else if currentNotch == .maximum && notch == .minimum {
            pinSearchVC.searchBar.resignFirstResponder()
            UIView.animate(withDuration: 0.25, delay: 0) {
                self.pinSearchVC.searchBarHeightConstraint.constant = 54
                self.pinSearchVC.searchBarDividerUIView.alpha = 0
                self.pinSearchVC.view.layoutIfNeeded()
                self.pinMapVC.setupBlurredStatusBar()
            }
        }
    }
    
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, didMoveOverlay overlayViewController: UIViewController, toNotchAt index: Int) {
        guard let notch = OverlayNotch.init(rawValue: index) else { return }
        currentNotch = notch
    }
    
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, willStartDraggingOverlay overlayViewController: UIViewController) {
        if currentNotch == .maximum {
            pinSearchVC.searchBar.resignFirstResponder()
        }
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        scrollViewDrivingOverlay overlayViewController: UIViewController) -> UIScrollView? {
        return (overlayViewController as? PinSearchViewController)?.tableView
    }
    
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        shouldStartDraggingOverlay overlayViewController: UIViewController,
                                        at point: CGPoint,
                                        in coordinateSpace: UICoordinateSpace) -> Bool {
        
        guard let header = (overlayViewController as? PinSearchViewController)?.notchView
        else {
            return false
        }
        let convertedPoint = coordinateSpace.convert(point, to: header)
        return header.bounds.contains(convertedPoint)
    }
}
