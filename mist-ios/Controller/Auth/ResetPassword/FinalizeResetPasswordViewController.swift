//
//  FinalizeResetPasswordViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import UIKit

class FinalizeResetPasswordViewController: KUIViewController, UITextFieldDelegate {
    
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
        isAuthKUIView = true
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
                button.configuration = ButtonConfigs.enabledConfig(title: "Finish")
            }
            else {
                button.configuration = ButtonConfigs.disabledConfig(title: "Finish")
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
        return count <= 25
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
        if let password = passwordTextField.text, let confirmPassword = confirmPasswordTextField.text {
            if password == confirmPassword {
                isSubmitting = true
                Task {
                    do {
                        try await AuthAPI.finalizeResetPassword(email: ResetPasswordContext.email, password: password)
                        CustomSwiftMessages.showInfo("Password successfully updated.", "Keep it safe and secure.", emoji: "🤐") { [self] in
                            isSubmitting = false
                            navigationController?.dismiss(animated: true)
                        }
                    } catch {
                        handleFailure("Your new password is not strong enough.", "Please try again.")
                    }
                }
            } else {
                handleFailure("The passwords don't match.", "Please try again.")
            }
        }
    }
    
    func handleFailure(_ message: String, _ recovery: String) {
        passwordTextField.text = ""
        confirmPasswordTextField.text = ""
        validateInput()
        CustomSwiftMessages.displayError(message, recovery)
        isSubmitting = false
    }
    
    func validateInput() {
        isValidInput = passwordTextField.text!.count >= 8 && confirmPasswordTextField.text!.count >= 8
    }
}
