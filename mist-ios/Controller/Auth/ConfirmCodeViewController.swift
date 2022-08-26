//
//  ConfirmCodeViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/25/22.
//

import Foundation

import UIKit

class ConfirmCodeViewController: KUIViewController, UITextFieldDelegate {
    
    enum ConfirmMethod: CaseIterable {
        case signupEmail, signupText, loginText, resetPhoneNumberEmail, resetPhoneNumberText
    }
    
    enum ResendState {
        case notsent, sending, sent
    }
    
    var recipient: String!
    var confirmMethod: ConfirmMethod!

    @IBOutlet weak var sentToLabel: UILabel!
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!

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
    var resendState: ResendState = .notsent {
        didSet {
            resendButton.setNeedsUpdateConfiguration()
        }
    }
    
    //MARK: - Initialization
    
    class func create(confirmMethod: ConfirmMethod) -> ConfirmCodeViewController {
        let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ConfirmCode) as! ConfirmCodeViewController
        switch confirmMethod {
        case .signupEmail, .resetPhoneNumberEmail:
            vc.recipient = AuthContext.email
        case .signupText, .loginText, .resetPhoneNumberText:
            vc.recipient = AuthContext.phoneNumber.asNationalPhoneNumber ?? AuthContext.phoneNumber
        }
        vc.confirmMethod = confirmMethod
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        validateInput()
        shouldNotAnimateKUIAccessoryInputView = true
        setupConfirmEmailTextField()
        setupContinueButton()
        setupResendButton()
        setupLabel()
        confirmTextField.becomeFirstResponder()
    }
    
    //MARK: - Setup
    
    func setupConfirmEmailTextField() {
        confirmTextField.delegate = self
        confirmTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        confirmTextField.layer.cornerRadius = 5
        let xconstraints: CGFloat = 50
        let textFieldWidth = view.frame.size.width - xconstraints
        let numberWidth: CGFloat = 14
        let spacing = (textFieldWidth / 7) - numberWidth
        confirmTextField.setLeftPaddingPoints(spacing)
        confirmTextField.defaultTextAttributes.updateValue(spacing, forKey: NSAttributedString.Key.kern)
    }
    
    func setupResendButton() {
        resendButton.configuration?.imagePadding = 5
        let resendAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 12)!]

        resendButton.configurationUpdateHandler = { [weak self] button in
            switch self?.resendState {
            case .notsent:
                button.isEnabled = true
                button.configuration?.showsActivityIndicator = false
                button.configuration?.image = nil
                button.configuration?.attributedTitle = AttributedString("resend", attributes: AttributeContainer(resendAttributes))
            case .sending:
                button.isEnabled = false
                button.configuration?.showsActivityIndicator = true
                button.configuration?.attributedTitle = AttributedString("resending", attributes: AttributeContainer(resendAttributes))
            case .sent:
                button.isEnabled = false
                button.configuration?.showsActivityIndicator = false
                button.configuration?.image = UIImage(systemName: "checkmark")
                button.configuration?.attributedTitle = AttributedString("resent", attributes: AttributeContainer(resendAttributes))
            case .none:
                break
            }
        }
    }
    
    func setupContinueButton() {
        let buttonTitle: String = confirmMethod == .loginText ? "login" : "continue"
        continueButton.configurationUpdateHandler = { [weak self] button in
            if button.isEnabled {
                button.configuration = ButtonConfigs.enabledConfig(title: buttonTitle)
            }
            else {
                if !(self?.isSubmitting ?? false) {
                    button.configuration = ButtonConfigs.disabledConfig(title: buttonTitle)
                }
            }
            button.configuration?.showsActivityIndicator = self?.isSubmitting ?? false
        }
    }
    
    func setupLabel() {
        sentToLabel.text! += recipient
    }
    
    //MARK: - User Interaction
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didPressedContinueButton(_ sender: Any) {
        tryToContinue()
    }
    
    @IBAction func didPressedResendButton(_ sender: UIButton) {
        resendState = .sending
        Task {
            do {
                try await resend()
            } catch {
                handleError(error)
            }
            resendState = .sent
        }
    }
    
    //MARK: - TextField Delegate
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        validateInput()
        if isValidInput {
            tryToContinue()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if isValidInput {
            tryToContinue()
        }
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let didAutofillTextfield = range == NSRange(location: 0, length: 0) && string.count > 1
        if didAutofillTextfield {
            DispatchQueue.main.async {
                self.tryToContinue()
            }
        }
        return textField.shouldChangeCharactersGivenMaxLengthOf(6, range, string)
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
        guard let code = confirmTextField.text else { return }
        isSubmitting = true
        Task {
            do {
                try await validate(validationCode: code)
                DispatchQueue.main.async {
                    self.continueToNextScreen()
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    func validateInput() {
        isValidInput = confirmTextField.text?.count == 6
    }
    
    func handleError(_ error: Error) {
        isSubmitting = false
        confirmTextField.text = ""
        CustomSwiftMessages.displayError(error)
    }
    
    //MARK: - ConfirmMethod Functions
    
    func resend() async throws {
        switch confirmMethod {
        case .signupEmail:
            try await AuthAPI.registerEmail(email: AuthContext.email)
        case .signupText:
            try await PhoneNumberAPI.registerNewPhoneNumber(email: AuthContext.email, phoneNumber: AuthContext.phoneNumber)
        case .resetPhoneNumberEmail:
            try await PhoneNumberAPI.requestResetEmail(email: AuthContext.email)
        case .resetPhoneNumberText:
            try await PhoneNumberAPI.requestResetText(email: AuthContext.email, phoneNumber: AuthContext.phoneNumber, resetToken: AuthContext.resetToken)
        case .loginText:
            try await PhoneNumberAPI.requestLoginCode(phoneNumber: AuthContext.phoneNumber)
        case .none:
            break
        }
    }
    
    func validate(validationCode: String) async throws {
        switch confirmMethod {
        case .signupEmail:
            try await AuthAPI.validateEmail(email: AuthContext.email, code: validationCode)
        case .signupText:
            try await PhoneNumberAPI.validateNewPhoneNumber(phoneNumber: AuthContext.phoneNumber, code: validationCode)
        case .resetPhoneNumberEmail:
            AuthContext.resetToken = try await PhoneNumberAPI.validateResetEmail(email: AuthContext.email, code: validationCode)
        case .resetPhoneNumberText:
            try await PhoneNumberAPI.validateResetText(phoneNumber: AuthContext.phoneNumber, code: validationCode, resetToken: AuthContext.resetToken)
        case .loginText:
            let authToken = try await PhoneNumberAPI.validateLoginCode(phoneNumber: AuthContext.phoneNumber, code: validationCode)
            try await UserService.singleton.logInWith(authToken: authToken)
            try await loadEverything()
        case .none:
            break
        }
    }
    
    @MainActor
    func continueToNextScreen() {
        switch confirmMethod {
        case .signupEmail:
            let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterNumber)
            self.navigationController?.pushViewController(vc, animated: true, completion: { [weak self] in
                self?.isSubmitting = false
            })
        case .signupText:
            let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterBios)
            self.navigationController?.pushViewController(vc, animated: true, completion: { [weak self] in
                self?.isSubmitting = false
            })
        case .resetPhoneNumberEmail:
            let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ResetNumber)
            self.navigationController?.pushViewController(vc, animated: true, completion: { [weak self] in
                self?.isSubmitting = false
            })
        case .resetPhoneNumberText:
            CustomSwiftMessages.showInfoCentered("phone number successfully updated", "", emoji: "👍") { [self] in
                isSubmitting = false
                navigationController?.dismiss(animated: true)
                AuthContext.reset()
            }
        case .loginText:
            transitionToHomeAndRequestPermissions() { }
            AuthContext.reset()
        case .none:
            break
        }
    }
}
