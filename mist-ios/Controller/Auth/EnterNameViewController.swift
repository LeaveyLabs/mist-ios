//
//  EnterNameViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 4/9/22.
//

import UIKit

class EnterNameViewController: KUIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    var isValidInput: Bool! {
        didSet {
            continueButton.isEnabled = isValidInput
            continueButton.setNeedsUpdateConfiguration()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        validateInput()
        isAuthKUIView = true
        setupPopGesture()
        setupTextFields()
        setupContinueButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        firstNameTextField.becomeFirstResponder()
        validateInput()
    }
    
    //MARK: - Setup
    
    func setupTextFields() {
        firstNameTextField.delegate = self
        firstNameTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        firstNameTextField.layer.cornerRadius = 5
        firstNameTextField.setLeftAndRightPadding(10)
        firstNameTextField.becomeFirstResponder()
        
        lastNameTextField.delegate = self
        lastNameTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        lastNameTextField.layer.cornerRadius = 5
        lastNameTextField.setLeftAndRightPadding(10)
    }
    
    func setupContinueButton() {
        continueButton.configurationUpdateHandler = { button in
            if button.isEnabled {
                button.configuration = ButtonConfigs.enabledConfig(title: "Continue")
            }
            else {
                button.configuration = ButtonConfigs.disabledConfig(title: "Continue")
            }
        }
    }
    
    //MARK: - User Interaction
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didPressedContinueButton(_ sender: UIButton) {
        tryToContinue()
    }
    
    //MARK: - TextField Delegate
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        validateInput()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        } else {
            if isValidInput {
                tryToContinue()
            }
        }
        return false
    }
    
    // Max length UI text field: https://stackoverflow.com/questions/25223407/max-length-uitextfield
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 15
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
        if let firstName = firstNameTextField.text, let lastName = lastNameTextField.text {
            AuthContext.firstName = firstName
            AuthContext.lastName = lastName
            let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.UploadProfilePicture)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func validateInput() {
        isValidInput = firstNameTextField.text!.count > 0 && lastNameTextField.text!.count > 0
    }
}
    

extension EnterNameViewController: UIGestureRecognizerDelegate {
    
    // Note: Must be called in viewDidLoad
    //(1 of 2) Enable swipe left to go back with a bar button item
    func setupPopGesture() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self;
    }
        
    //(2 of 2) Enable swipe left to go back with a bar button item
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

