//
//  OkViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

typealias PinMapModalCompletionHandler = ((String?) -> Void)

protocol PinMapModalDelegate {
    func reselectAnnotation()
}

//modal with a custom size
//https://stackoverflow.com/questions/54737884/changing-the-size-of-a-modal-view-controller

class PinMapModalViewController: CustomSheetViewController, UITextFieldDelegate {

    var completionHandler: PinMapModalCompletionHandler!

    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var reselectButton: UIButton!
    @IBOutlet weak var locationDescriptionTextField: UITextField!

    var mapDelegate: PinMapModalDelegate?
    var annotation: PostAnnotation!
    var xsIndentFirst: Bool! = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectButton.layer.cornerRadius = 5
        reselectButton.layer.cornerRadius = 5
        containingView.layer.cornerRadius = 15
        disableSelectButton()
        
        isModalInPresentation = true //prevents the VC from being dismissed by the user

        let wasTapped = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        view.addGestureRecognizer(wasTapped)
        
        locationDescriptionTextField.delegate = self
        setupSheet(prefersGrabberVisible: true,
                   detents: [Constants.Detents.s, Constants.Detents.xs, Constants.Detents.xl],
                   largestUndimmedDetentIdentifier: "xl")
    }
    
    //MARK: - User Interaction
    
    @IBAction func selectButtonDidPressed(_ sender: UIButton) {
        completionHandler(locationDescriptionTextField.text)
    }
    
    @IBAction func reselectButtonDidPressed(_ sender: UIButton) {
        completionHandler(nil)
    }
    
    //MARK: - TextField Delegate
    
    @IBAction func locationDescriptionTextFieldDidGetEditted(_ sender: UITextField) {
        annotation.title = locationDescriptionTextField.text
        if locationDescriptionTextField.text!.isEmpty {
            disableSelectButton()
        } else {
            enableSelectButton()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        locationDescriptionTextField.resignFirstResponder()
    }
    
    
    //MARK: - Helpers
    
    @objc func handleBackgroundTap() {
        if mySheetPresentationController.selectedDetentIdentifier?.rawValue == "xs" {
            toggleSheetSizeTo(sheetSize: "s")
            mapDelegate?.reselectAnnotation()
        }
    }
    
    func clearAllFields() {
        locationDescriptionTextField.text! = ""
    }
    
    func enableSelectButton() {
        selectButton.isEnabled = true;
        selectButton.alpha = 1;
    }
    
    func disableSelectButton() {
        selectButton.isEnabled = false;
        selectButton.alpha = 0.99;
    }
    
}
