//
//  EnterEmailViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/29/22.
//

import UIKit

class EnterEmailViewController: KUIViewController, UITextFieldDelegate {

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
            continueButton.isEnabled = false
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
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
        //Three states:
        // 1. enabled
        // 2. disabled (faded white text)
        // 3. disabled and submitting (dark grey foreground) bc i dont think you can change the activityIndicator color
        continueButton.configurationUpdateHandler = { [weak self] button in
            if button.isEnabled {
                button.configuration = ButtonConfigs.shared.enabledConfig
            }
            else {
                if !(self?.isSubmitting ?? false) {
                    button.configuration = ButtonConfigs.shared.disabledConfig
                }
            }
            button.configuration?.showsActivityIndicator = self?.isSubmitting ?? false
        }
    }
    
    //MARK: - User Interaction
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
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
        // If you've inputted an email
        if let email = enterEmailTextField.text {
            Task {
                isSubmitting = true
                do {
                    // Send a validation email
                    try await AuthAPI.registerEmail(email: email)
                    // Move to the next code view
                    AuthContext.email = email
                    let vc = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ConfirmEmail)
                    self.navigationController?.pushViewController(vc, animated: true, completion: { [weak self] in
                        self?.isSubmitting = false
                    })
                } catch {
                    print(error)
                    isSubmitting = false
                }
            }
        }
    }
    
    func validateInput() {
        isValidInput = enterEmailTextField.text?.suffix(8) == "@usc.edu"
    }
    
}

extension EnterEmailViewController: UIGestureRecognizerDelegate {
    
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
