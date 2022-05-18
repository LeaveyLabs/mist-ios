//
//  SheetViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 5/17/22.
//

import UIKit

//hack to ensure that subclass also implements certain methods which are defined in the protocol
//https://stackoverflow.com/questions/24111356/swift-class-method-which-must-be-overridden-by-subclass


protocol SheetDismissDelegate {
    func handleSheetDismiss()
}

extension Constants {
    struct Detents {
        static let xs: UISheetPresentationController.Detent = ._detent(withIdentifier: "xs", constant: 50)
        static let s: UISheetPresentationController.Detent = ._detent(withIdentifier: "s", constant: 300)
        static let m: UISheetPresentationController.Detent = ._detent(withIdentifier: "m", constant: 500)
        static let l: UISheetPresentationController.Detent = ._detent(withIdentifier: "l", constant: 700)
        static let xl: UISheetPresentationController.Detent = ._detent(withIdentifier: "xl", constant: 900)
    }
}

class SheetViewController: UIViewController, UIViewControllerTransitioningDelegate {

    @IBOutlet weak var containingView: UIView!
    
    var prefersGrabberVisible: Bool!
    var detents: [UISheetPresentationController.Detent]!
    var bgInteractionEnabled: Bool! = true
    
    var sheetDelegate: UISheetPresentationControllerDelegate? //Allows lower level vc to detect when the sheet changes sizes and remains up
    var sheetDismissDelegate: SheetDismissDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        containingView.layer.cornerRadius = 10
        //containingView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Only curve top corners
        
        view.layer.cornerRadius = 15
        
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    func setupSheet(prefersGrabberVisible: Bool,
                    detents: [UISheetPresentationController.Detent],
                    bgInteractionEnabled: Bool) {
        self.prefersGrabberVisible = prefersGrabberVisible
        self.detents = detents
        self.bgInteractionEnabled = bgInteractionEnabled
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        let controller: UISheetPresentationController = .init(presentedViewController: presented, presenting: presenting)
        controller.delegate = sheetDelegate
        if bgInteractionEnabled {
            controller.largestUndimmedDetentIdentifier = .init(rawValue: "xs")
        }
        controller.prefersGrabberVisible = prefersGrabberVisible
        controller.detents = detents
                
        return controller
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sheetDismissDelegate?.handleSheetDismiss()
    }
}
