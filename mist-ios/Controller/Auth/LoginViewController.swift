//
//  EnterCodeViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/29/22.
//

import UIKit
import SwiftMessages

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
            loginButton.isEnabled = !isSubmitting
            loginButton.setNeedsUpdateConfiguration()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        validateInput()
        isAuthKUIView = true
        setupPopGesture()
        setupTextFields()
        setupLoginButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let messageView = MessageView.viewFromNib(layout: .cardView)
        
        messageView.configureTheme(backgroundColor: .systemRed, foregroundColor: .white, iconImage: nil, iconText: "😔")
        messageView.configureDropShadow()
        messageView.configureContent(title: "Something went wrong.",
                                     body: "Please try again.",
                                     iconImage: nil,
                                     iconText: "😔",
                                     buttonImage: UIImage(systemName: "xmark"),
                                     buttonTitle: nil) { button in
            SwiftMessages.hide()
        }
        
        var messageConfig = SwiftMessages.Config()
        messageConfig.keyboardTrackingView = KeyboardTrackingView()
        messageConfig.presentationStyle = .bottom
        messageConfig.duration = .seconds(seconds: 3)

        SwiftMessages.show(config: messageConfig, view: messageView)
        
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
                button.configuration = ButtonConfigs.enabledConfig(title: "Login")
            } else {
                if !(self?.isSubmitting ?? false) {
                    button.configuration = ButtonConfigs.disabledConfig(title: "Login")
                }
            }
            button.configuration?.showsActivityIndicator = self?.isSubmitting ?? false
        }
    }
    
    //MARK: - User Interaction
    
    @IBAction func signupButtonDidPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: false)
    }
    
    @IBAction func loginButtonDidPressed(_ sender: Any) {
        tryToLogin()
    }
    
    @IBAction func forgotButtonDidPressed(_ sender: UIButton) {
        
    }
    
    //MARK: - TextField Delegate
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        validateInput()
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
                    try await UserService.singleton.logIn(username: username, password: password)
                    transitionToStoryboard(storyboardID: Constants.SBID.SB.Main,
                                           viewControllerID: Constants.SBID.VC.TabBarController,
                                           duration: 1) { [weak self] _ in
                        self?.isSubmitting = false
                    }
                } catch {
                    print("almost!")
                    handleLoginFail()
                    print(error);
                }
            }
        }
    }
    
    func handleLoginFail() {
        isSubmitting = false
        passwordTextField.text = ""
    }
    
    func validateInput() {
        isValidInput = !passwordTextField.text!.isEmpty && !usernameTextField.text!.isEmpty
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
