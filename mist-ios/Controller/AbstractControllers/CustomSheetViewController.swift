//
//  SheetViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 5/17/22.
//

import UIKit

//hack to ensure that subclass also implements certain methods which are defined in the protocol
//https://stackoverflow.com/questions/24111356/swift-class-method-which-must-be-overridden-by-subclass


protocol childDismissDelegate {
    func handleChildWillDismiss()
    func handleChildDidDismiss()
}

extension Constants {
    struct Detents {
        static let zil: UISheetPresentationController.Detent = ._detent(withIdentifier: "zil", constant: -50)
        static let xs: UISheetPresentationController.Detent = ._detent(withIdentifier: "xs", constant: 50)
        static let s: UISheetPresentationController.Detent = ._detent(withIdentifier: "s", constant: 300)
        static let m: UISheetPresentationController.Detent = ._detent(withIdentifier: "m", constant: 400)
        static let l: UISheetPresentationController.Detent = ._detent(withIdentifier: "l", constant: 700)
        static let xl: UISheetPresentationController.Detent = ._detent(withIdentifier: "xl", constant: 900)
    }
}

class CustomSheetViewController: UIViewController, UIViewControllerTransitioningDelegate {

    @IBOutlet weak var containingView: UIView!
    lazy var mySheetPresentationController = presentationController as! UISheetPresentationController
    
    var prefersGrabberVisible: Bool!
    var detents: [UISheetPresentationController.Detent]!
    var largestUndimmedDetentIdentifier: String? = nil
        
    var sheetDelegate: UISheetPresentationControllerDelegate? //Allows lower level vc to detect when the sheet changes sizes and remains up
    var sheetDismissDelegate: childDismissDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.cornerRadius = 15
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Only curve top corners
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    func setupSheet(prefersGrabberVisible: Bool,
                    detents: [UISheetPresentationController.Detent],
                    largestUndimmedDetentIdentifier: String?) {
        self.prefersGrabberVisible = prefersGrabberVisible
        self.detents = detents
        self.largestUndimmedDetentIdentifier = largestUndimmedDetentIdentifier
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        let controller: UISheetPresentationController = .init(presentedViewController: presented, presenting: presenting)
        controller.delegate = sheetDelegate
        if let largestUndimmedDetentIdentifier = largestUndimmedDetentIdentifier {
            controller.largestUndimmedDetentIdentifier = .init(rawValue: largestUndimmedDetentIdentifier)
        }
        controller.prefersGrabberVisible = prefersGrabberVisible
        controller.detents = detents
        controller.preferredCornerRadius = 20
        
        return controller
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sheetDismissDelegate?.handleChildWillDismiss()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        sheetDismissDelegate?.handleChildDidDismiss()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("will transition to")
    }
    
    func toggleSheetSizeTo(sheetSize: String) {
        mySheetPresentationController.animateChanges {
            mySheetPresentationController.selectedDetentIdentifier = .init(rawValue: sheetSize)
        }
    }
    
}
