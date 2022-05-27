//
//  ChooseUsernameViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 4/9/22.
//

import UIKit

class ChooseUsernameViewController: KUIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
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
        setupPopGesture()
        setupTextFields()
        setupContinueButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        usernameTextField.becomeFirstResponder()
        validateInput()
    }
    
    //MARK: - Setup
    
    func setupTextFields() {
        usernameTextField.delegate = self
        usernameTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        usernameTextField.layer.cornerRadius = 5
        usernameTextField.setLeftAndRightPadding(10)
        usernameTextField.becomeFirstResponder()
    }
    
    func setupContinueButton() {
        continueButton.configurationUpdateHandler = { [weak self] button in
            if button.isEnabled {
                button.configuration = ButtonConfigs.enabledConfig(title: "Continue")
            }
            else {
                button.configuration = ButtonConfigs.disabledConfig(title: "Continue")
            }
            button.configuration?.showsActivityIndicator = self?.isSubmitting ?? false
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
        return count <= 20
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
        if let username = usernameTextField.text {
            isSubmitting = true
            Task {
                do {
                    try await AuthAPI.validateUsername(username: username)
                    AuthContext.username = username
                    let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterName);
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
        isValidInput = false
        displayErrorMessage(errorDescription: error.localizedDescription)
    }
    
    func validateInput() {
        isValidInput = usernameTextField.text!.count > 3
    }
}
    

extension ChooseUsernameViewController: UIGestureRecognizerDelegate {
    
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

