//
//  OkViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

typealias PinMapModalCompletionHandler = ((String?) -> Void)

class PinMapModalViewController: UIViewController, UITextFieldDelegate {

    var completionHandler: PinMapModalCompletionHandler!

    @IBOutlet weak var containingView: UIView!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var reselectButton: UIButton!
    @IBOutlet weak var locationDescriptionTextField: UITextField!
    
    var annotation: MKPointAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectButton.layer.cornerRadius = 5
        reselectButton.layer.cornerRadius = 5
        containingView.layer.cornerRadius = 15
        disableSelectButton()
        locationDescriptionTextField.delegate = self
    }
    
    //create a postVC for a given post. postVC should never exist without a post
    class func createPinMapModalVCFor(_ annotation: MKPointAnnotation) -> PinMapModalViewController {
        let pinMapModalVC =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.PinMapModal) as! PinMapModalViewController
        pinMapModalVC.annotation = annotation
        return pinMapModalVC
    }
    
    @IBAction func selectButtonDidPressed(_ sender: UIButton) {
        completionHandler(locationDescriptionTextField.text)
    }
    
    @IBAction func reselectButtonDidPressed(_ sender: UIButton) {
        completionHandler(nil)
    }
    
    //MARK: -TextField Delegate
    @IBAction func locationDescriptionTextFieldDidGetEditted(_ sender: UITextField) {
        if locationDescriptionTextField.text!.isEmpty {
            disableSelectButton()
        } else {
            enableSelectButton()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        locationDescriptionTextField.resignFirstResponder()
    }
    
    //MARK: -Helpers
    
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
