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
    var isSubmitting: Bool = false {
        didSet {
            continueButton.isEnabled = !isSubmitting
            continueButton.setNeedsUpdateConfiguration()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        validateInput()
        shouldNotAnimateKUIAccessoryInputView = true
        setupTextFields()
        setupContinueButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableInteractivePopGesture()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        enableInteractivePopGesture()
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
                button.configuration = ButtonConfigs.enabledConfig(title: "continue")
            }
            else {
                button.configuration = ButtonConfigs.disabledConfig(title: "continue")
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
        if textField == passwordTextField {
            confirmPasswordTextField.becomeFirstResponder()
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
        return count <= Constants.maxPasswordLength
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
//        if let password = passwordTextField.text, let confirmPassword = confirmPasswordTextField.text {
//            if password == confirmPassword {
//                isSubmitting = true
//                Task {
//                    do {
////                        let emailMinusDomain = AuthContext.email.components(separatedBy: "@")[0]
////                        try await AuthAPI.validatePassword(username: emailMinusDomain, password: password)
//                        AuthContext.password = password
//                        let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterBios)
//                        self.navigationController?.pushViewController(vc, animated: true)
//                    } catch {
//                        handleFailure("Not strong enough", "Cmon now, that's just too easy")
//                    }
//                    isSubmitting = false
//                }
//            } else {
//                handleFailure("The passwords don't match", "Your worst nightmare")
//            }
//        }
    }
    
    func handleFailure(_ message: String, _ explanation: String) {
        passwordTextField.text = ""
        confirmPasswordTextField.text = ""
        validateInput()
        CustomSwiftMessages.displayError(message, explanation)
    }
    
    func validateInput() {
        isValidInput = passwordTextField.text!.count >= 8 && confirmPasswordTextField.text!.count >= 8
    }
}
