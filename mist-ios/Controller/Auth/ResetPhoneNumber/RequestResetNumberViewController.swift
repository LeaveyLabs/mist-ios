//
//  RequestResetPasswordViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import UIKit

class RequestResetNumberViewController: KUIViewController, UITextFieldDelegate {

    @IBOutlet weak var enterEmailTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    var isValidInput: Bool! {
        didSet {
            continueButton.isEnabled = isValidInput
        }
    }
    var isSubmitting: Bool = false {
        didSet {
            continueButton.isSelected = isSubmitting
            continueButton.setTitle(isSubmitting ? "" : "continue", for: .normal)
            continueButton.loadingIndicator(isSubmitting)
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isValidInput = false
        shouldNotAnimateKUIAccessoryInputView = true
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
        AuthContext.reset()
    }
    
    //MARK: - Setup
    
    func setupEnterEmailTextField() {
        enterEmailTextField.delegate = self
        enterEmailTextField.layer.cornerRadius = 5
        enterEmailTextField.setLeftAndRightPadding(10)
        enterEmailTextField.becomeFirstResponder()
    }
    
    func setupContinueButton() {
        continueButton.roundCornersViaCornerRadius(radius: 10)
        continueButton.clipsToBounds = true
        continueButton.isEnabled = false
        continueButton.setBackgroundImage(UIImage.imageFromColor(color: Constants.Color.mistLilac), for: .normal)
        continueButton.setBackgroundImage(UIImage.imageFromColor(color: Constants.Color.mistLilac.withAlphaComponent(0.2)), for: .disabled)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.setTitleColor(Constants.Color.mistLilac, for: .disabled)
        continueButton.setTitle("continue", for: .normal)
    }
    
    func setupBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(goBack))
        navigationController?.navigationBar.tintColor = Constants.Color.mistBlack
    }
    
    //MARK: - User Interaction
    
    @objc func goBack() {
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let didAutofillTextfield = range == NSRange(location: 0, length: 0) && string.count > 1
        if didAutofillTextfield {
            DispatchQueue.main.async {
                self.tryToContinue()
            }
        }
        return true
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
        guard let email = enterEmailTextField.text?.lowercased() else { return }
        Task {
            isSubmitting = true
            do {
                try await PhoneNumberAPI.requestResetEmail(email: email)
                AuthContext.email = email
                let vc = ConfirmCodeViewController.create(confirmMethod: .resetPhoneNumberEmail)
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
        validateInput()
        CustomSwiftMessages.displayError(error)
    }
    
    func validateInput() {
        isValidInput = enterEmailTextField.text?.contains("@")
//        isValidInput = enterEmailTextField.text?.suffix(8).lowercased() == "@usc.edu"
    }
    
}

// UIGestureRecognizerDelegate (already inherited in an extension)

extension RequestResetNumberViewController {
    
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
