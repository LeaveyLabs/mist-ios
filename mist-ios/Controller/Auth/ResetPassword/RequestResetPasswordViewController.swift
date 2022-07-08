//
//  RequestResetPasswordViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import UIKit

class RequestResetPasswordViewController: KUIViewController, UITextFieldDelegate {

    @IBOutlet weak var enterEmailTextField: UITextField!
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
        
        isValidInput = false
        isAuthKUIView = true
        setupPopGesture()
        setupEnterEmailTextField()
        setupContinueButton() //uncomment this button for standard button behavior, where !isEnabled greys it out
        setupBackButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        disableInteractivePopGesture() //because it's the root view controller of a navigation vc
        enterEmailTextField.becomeFirstResponder()
        validateInput()
    }
    
    //MARK: - Setup
    
    func setupEnterEmailTextField() {
        enterEmailTextField.delegate = self
        enterEmailTextField.layer.cornerRadius = 5
        enterEmailTextField.setLeftAndRightPadding(10)
        enterEmailTextField.becomeFirstResponder()
    }
    
    func setupContinueButton() {
        continueButton.configurationUpdateHandler = { [weak self] button in
            if button.isEnabled {
                button.configuration = ButtonConfigs.enabledConfig(title: "Continue")
            }
            else {
                if !(self?.isSubmitting ?? false) {
                    button.configuration = ButtonConfigs.disabledConfig(title: "Continue")
                }
            }
            button.configuration?.showsActivityIndicator = self?.isSubmitting ?? false
        }
    }
    
    func setupBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(goBack))
    }
    
    //MARK: - User Interaction
    
    @objc func goBack() {
        print("TRYING TO GO BACK")
        navigationController?.dismiss(animated: true)
    }
    
    @IBAction func didPressedContinueButton(_ sender: Any) {
        tryToContinue()
    }
    
    //MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if isValidInput {
            tryToContinue()
        }
        return false
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        validateInput()
        let maxLength = 30
        if sender.text!.count > maxLength {
            sender.deleteBackward()
        }
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
        if let email = enterEmailTextField.text?.lowercased() {
            Task {
                isSubmitting = true
                do {
                    try await AuthAPI.requestResetPassword(email: email)
                    // Move to the next code view
                    ResetPasswordContext.email = email
                    let vc = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ValidateResetPassword)
                    self.navigationController?.pushViewController(vc, animated: true, completion: { [weak self] in
                        self?.isSubmitting = false
                    })
                } catch {
                    handleFailure(error)
                }
            }
        }
    }
    
    func handleFailure(_ error: Error) {
        isSubmitting = false
        enterEmailTextField.text = ""
        validateInput()
        CustomSwiftMessages.displayError(error)
    }
    
    func validateInput() {
        isValidInput = enterEmailTextField.text?.contains("@")
//        isValidInput = enterEmailTextField.text?.suffix(8).lowercased() == "@usc.edu"
    }
    
}

// UIGestureRecognizerDelegate (already inherited in an extension)

extension RequestResetPasswordViewController {
    
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
