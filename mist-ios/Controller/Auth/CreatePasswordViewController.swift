//
//  EnterPasswordViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 4/9/22.
//

import UIKit

class CreatePasswordViewController: KUIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
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
    
    //MARK: - Setup
    
    func setupTextFields() {
        passwordTextField.delegate = self
        passwordTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        passwordTextField.layer.cornerRadius = 5
        passwordTextField.setLeftAndRightPadding(10)
        passwordTextField.becomeFirstResponder()
        
        confirmPasswordTextField.delegate = self
        confirmPasswordTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        confirmPasswordTextField.layer.cornerRadius = 5
        confirmPasswordTextField.setLeftAndRightPadding(10)
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
        if isValidInput {
            tryToContinue()
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
        return count <= 6
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
        if let password = passwordTextField.text, let confirmPassword = confirmPasswordTextField.text {
            if password == confirmPassword {
                AuthContext.password = password
                let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterName);
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                
            }
        }
    }
    
    func validateInput() {
        isValidInput = passwordTextField.text!.count >= 8 && confirmPasswordTextField.text!.count >= 8
    }
}
    

extension CreatePasswordViewController: UIGestureRecognizerDelegate {
    
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

