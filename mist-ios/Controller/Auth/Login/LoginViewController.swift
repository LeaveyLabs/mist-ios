//
//  LoginViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/25/22.
//

import Foundation
import UIKit
import PhoneNumberKit

class LoginViewController: KUIViewController, UITextFieldDelegate {

    @IBOutlet weak var enterNumberTextField: PhoneNumberTextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var enterNumberTextFieldWrapperView: UIView!
    
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
        setupEnterNumberTextField()
        setupContinueButton() //uncomment this button for standard button behavior, where !isEnabled greys it out
        setupBackButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        enableInteractivePopGesture()
        AuthContext.reset()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enterNumberTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disableInteractivePopGesture()
    }
    
    //MARK: - Setup
    
    func setupEnterNumberTextField() {
        enterNumberTextFieldWrapperView.layer.cornerRadius = 5
        enterNumberTextFieldWrapperView.layer.cornerCurve = .continuous
        enterNumberTextField.delegate = self
        enterNumberTextField.countryCodePlaceholderColor = .red
        enterNumberTextField.withFlag = true
        enterNumberTextField.withPrefix = true
//        enterNumberTextField.withExamplePlaceholder = true
    }
    
    func setupContinueButton() {
        //Three states:
        // 1. enabled
        // 2. disabled (faded white text)
        // 3. disabled and submitting (dark grey foreground) bc i dont think you can change the activityIndicator color
        continueButton.configurationUpdateHandler = { [weak self] button in
            if button.isEnabled {
                button.configuration = ButtonConfigs.enabledConfig(title: "continue")
            }
            else {
                if !(self?.isSubmitting ?? false) {
                    button.configuration = ButtonConfigs.disabledConfig(title: "continue")
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
    
    @IBAction func resetButtonDidPressed(_ sender: UIButton) {
        let resetVC = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.RequestReset)
        let navigationController = UINavigationController(rootViewController: resetVC)
        present(navigationController, animated: true)
    }
    
    //MARK: - TextField Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let didAutofillTextfield = range == NSRange(location: 0, length: 0) && string.count > 1
        if didAutofillTextfield {
            DispatchQueue.main.async {
                self.tryToContinue()
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if isValidInput {
            tryToContinue()
        }
        return false
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        let maxLength = 17 //the max length for US numbers
        if sender.text!.count > maxLength {
            sender.deleteBackward()
        }
        validateInput()
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
        guard let number = enterNumberTextField.text else { return }
        isSubmitting = true
        Task {
            do {
                if let number = number.asE164PhoneNumber {
                    try await PhoneNumberAPI.requestLoginCode(phoneNumber: number)
                    AuthContext.phoneNumber = number
                } else {
                    AuthContext.phoneNumber = AuthContext.APPLE_PHONE_NUMBER
                }
                let vc = ConfirmCodeViewController.create(confirmMethod: .loginText)
                self.navigationController?.pushViewController(vc, animated: true, completion: { [weak self] in
                    self?.isSubmitting = false
                })
            } catch {
                handleFailure(error)
            }
        }
    }
    
    func handleFailure(_ error: Error) {
        isSubmitting = false
        enterNumberTextField.text = ""
        validateInput()
        CustomSwiftMessages.displayError(error)
    }
    
    func validateInput() {
        isValidInput = enterNumberTextField.text?.asE164PhoneNumber != nil || enterNumberTextField.text?.filter("1234567890".contains) == AuthContext.APPLE_PHONE_NUMBER
    }
    
}

// UIGestureRecognizerDelegate (already inherited in an extension)

extension LoginViewController {
    
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
