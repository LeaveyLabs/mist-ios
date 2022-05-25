//
//  EnterCodeViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/29/22.
//

import UIKit

class LoginViewController: KUIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    var isValidInput: Bool! {
        didSet {
            loginButton.isEnabled = isValidInput
            loginButton.setNeedsUpdateConfiguration()
        }
    }
    var isSubmitting: Bool = false {
        didSet {
            loginButton.isEnabled = false
            loginButton.setNeedsUpdateConfiguration()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isValidInput = false
        isAuthKUIView = true
        setupPopGesture()
        setupTextFields()
        setupLoginButton()
    }
    
    //MARK: - Setup
    
    func setupTextFields() {
        usernameTextField.delegate = self
        usernameTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        usernameTextField.layer.cornerRadius = 5
        usernameTextField.setLeftAndRightPadding(10)
        usernameTextField.becomeFirstResponder()
        
        passwordTextField.delegate = self
        passwordTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        passwordTextField.layer.cornerRadius = 5
        passwordTextField.setLeftAndRightPadding(10)
    }
    
    func setupLoginButton() {
        loginButton.configurationUpdateHandler = { [weak self] button in
            if button.isEnabled {
                button.configuration = ButtonConfigs.shared.enabledConfig
            } else {
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
    
    @IBAction func loginButtonDidPressed(_ sender: Any) {
        tryToLogin()
    }
    
    @IBAction func forgotButtonDidPressed(_ sender: UIButton) {
        
    }
    
    //MARK: - TextField Delegate
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        isValidInput = !passwordTextField.text!.isEmpty && !usernameTextField.text!.isEmpty
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            if isValidInput {
                tryToLogin()
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
        return count <= 30
    }
    
    //MARK: - Helpers
    
    func tryToLogin() {
        // If you've inputted the code
        if let password = passwordTextField.text, let username = usernameTextField.text {
            isSubmitting = true
            Task {
                do {
//                    try await AuthAPI.login()
                    transitionToHomeVC()
                } catch {
                    isSubmitting = false
                    print(error);
                }
            }
        }
    }
    
    // Reference: https://stackoverflow.com/questions/41144523/swap-rootviewcontroller-with-animation
    func transitionToHomeVC() {
        let sb = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil)
        let homeVC = sb.instantiateViewController(withIdentifier: Constants.SBID.VC.TabBarController)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let delegate = windowScene.delegate as? SceneDelegate, let window = delegate.window else {
            return
        }

        // Set the new rootViewController of the window.
        // Calling "UIView.transition" below will animate the swap.
        delegate.window?.rootViewController = homeVC

        // A mask of options indicating how you want to perform the animations.
        let options: UIView.AnimationOptions = .transitionCrossDissolve

        // The duration of the transition animation, measured in seconds.
        let duration: TimeInterval = 1

        // Creates a transition animation.
        // Though `animations` is optional, the documentation tells us that it must not be nil. ¯\_(ツ)_/¯
        UIView.transition(with: window, duration: duration, options: options, animations: {}, completion:
        { [weak self] completed in
            self?.isSubmitting = false
        })
    }
}

extension LoginViewController: UIGestureRecognizerDelegate {
    
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
