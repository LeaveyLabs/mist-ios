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
            continueButton.isEnabled = !isSubmitting
            continueButton.setNeedsUpdateConfiguration()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        isValidInput = false
        validateInput()
        shouldNotAnimateKUIAccessoryInputView = true
        setupPopGesture()
        setupEnterEmailTextField()
        setupContinueButton() //uncomment this button for standard button behavior, where !isEnabled greys it out
        setupBackButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        enableInteractivePopGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enterEmailTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disableInteractivePopGesture()
    }
    
    //MARK: - Setup
    
    func setupEnterEmailTextField() {
        enterEmailTextField.delegate = self
        enterEmailTextField.layer.cornerRadius = 5
        enterEmailTextField.setLeftAndRightPadding(10)
    }
    
    func setupContinueButton() {
        //Three states:
        // 1. enabled
        // 2. disabled (faded white text)
        // 3. disabled and submitting (dark grey foreground) bc i dont think you can change the activityIndicator color
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
    }
    
    //MARK: - User Interaction
    
    @objc func goBack() {
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
        if let email = enterEmailTextField.text?.lowercased() {
            isSubmitting = true
            Task {
                do {
                    try await AuthAPI.registerEmail(email: email)
                    AuthContext.email = email
                    let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ConfirmEmail)
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
        CustomSwiftMessages.displayError("That email is already taken", "Please enter another one")
    }
    
    func validateInput() {
        isValidInput = enterEmailTextField.text?.contains("@")
//        isValidInput = enterEmailTextField.text?.suffix(8).lowercased() == "@usc.edu"
    }
    
}

// UIGestureRecognizerDelegate (already inherited in an extension)

extension EnterEmailViewController {
    
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
