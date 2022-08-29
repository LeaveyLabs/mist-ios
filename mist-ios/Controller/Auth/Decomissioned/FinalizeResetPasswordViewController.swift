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
        setupBackButton()
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
                button.configuration = ButtonConfigs.enabledConfig(title: "finish")
            }
            else {
                button.configuration = ButtonConfigs.disabledConfig(title: "finish")
            }
            button.configuration?.showsActivityIndicator = self.isSubmitting
        }
    }
    
    func setupBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: self, action: nil)
    }
    
    //MARK: - User Interaction
    
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
        return count <= Constants.maxPasswordLength
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
//        if let password = passwordTextField.text, let confirmPassword = confirmPasswordTextField.text {
//            if password == confirmPassword {
//                isSubmitting = true
//                Task {
//                    do {
//                        try await AuthAPI.finalizeResetPassword(email: ResetPasswordContext.email, password: password)
//                        CustomSwiftMessages.showInfoCentered("password successfully updated.", "keep it safe and secure", emoji: "🤐") { [self] in
//                            isSubmitting = false
//                            navigationController?.dismiss(animated: true)
//                        }
//                    } catch {
//                        handleFailure("not strong enough", "cmon now, that's just too easy")
//                    }
//                }
//            } else {
//                handleFailure("the passwords don't match", "your worst nightmare")
//            }
//        }
    }
    
    func handleFailure(_ message: String, _ recovery: String) {
        passwordTextField.becomeFirstResponder()
        CustomSwiftMessages.displayError(message, recovery)
        passwordTextField.text = ""
        confirmPasswordTextField.text = ""
        validateInput()
        isSubmitting = false
    }
    
    func validateInput() {
        isValidInput = passwordTextField.text!.count >= 8 && confirmPasswordTextField.text!.count >= 8
    }
}
