//
//  EnterCodeViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/29/22.
//

enum ResendState {
    case notsent, sending, sent
}

import UIKit

class ConfirmEmailViewController: KUIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var confirmEmailTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var errorView: SpringView!
    @IBOutlet weak var agreementLabel: UILabel!

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailLabel.text! += AuthContext.email
        
        errorView.isHidden = true //we're using SwiftMessages for error handling now, not this custom view
        validateInput()
        shouldNotAnimateKUIAccessoryInputView = true
        setupConfirmEmailTextField()
        setupContinueButton()
        setupResendButton()
//        setupAgreementLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableInteractivePopGesture()
    }
    
    //MARK: - Setup
    
    func setupConfirmEmailTextField() {
        confirmEmailTextField.delegate = self
        confirmEmailTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        confirmEmailTextField.layer.cornerRadius = 5
        confirmEmailTextField.setLeftPaddingPoints(25)
        confirmEmailTextField.defaultTextAttributes.updateValue(33, forKey: NSAttributedString.Key.kern)
        confirmEmailTextField.becomeFirstResponder()
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
                button.configuration?.attributedTitle = AttributedString("Resend", attributes: AttributeContainer(resendAttributes))
            case .sending:
                button.isEnabled = false
                button.configuration?.showsActivityIndicator = true
                button.configuration?.attributedTitle = AttributedString("Resending", attributes: AttributeContainer(resendAttributes))
            case .sent:
                button.isEnabled = false
                button.configuration?.showsActivityIndicator = false
                button.configuration?.image = UIImage(systemName: "checkmark")
                button.configuration?.attributedTitle = AttributedString("Resent", attributes: AttributeContainer(resendAttributes))
            case .none:
                break
            }
        }
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
    
    func setupAgreementLabel() {
        let attributedString = NSMutableAttributedString(string: "By clicking continue, you agree to our Terms of Use and Privacy Policy.")
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemBlue, range: .init(location: 39, length: 12))
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemBlue, range: .init(location: 56, length: 14))
        agreementLabel.attributedText = attributedString
    }
    
    //MARK: - User Interaction
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didPressedContinueButton(_ sender: Any) {
        tryToContinue()
    }
    
    @IBAction func didPressedResendButton(_ sender: UIButton) {
        resendCode()
    }
    
    @IBAction func termsButtonDidTapped(_ sender: UIButton) {
        openURL(URL(string: "https://www.getmist.app/terms-of-use")!)
    }
    
    @IBAction func privacyPolicyButtonDidTapped(_ sender: UIButton) {
        openURL(URL(string: "https://www.getmist.app/privacy-policy")!)
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textField.shouldChangeCharactersGivenMaxLengthOf(6, range, string)
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
        if let code = confirmEmailTextField.text {
            isSubmitting = true
            Task {
                do {
                    try await AuthAPI.validateEmail(email: AuthContext.email, code: code)
                    let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.CreatePassword);
                    self.navigationController?.pushViewController(vc, animated: true, completion: { [weak self] in
                        self?.isSubmitting = false
                    })
                } catch {
                    handleError(error)
                }
            }
        }
    }
    
    func resendCode() {
        resendState = .sending
        errorView.isHidden = true
        Task {
            do {
                // Send another validation email
                try await AuthAPI.registerEmail(email: AuthContext.email)
            } catch {
                handleError(error)
            }
            resendState = .sent
        }
    }
    
    func validateInput() {
        isValidInput = confirmEmailTextField.text?.count == 6
    }
}

//we're using SwiftMessages instead for error handling. Leaving this code just as a reference
// Error View functions
extension ConfirmEmailViewController {
    
    func setupErrorLabel() {
        errorView.layer.cornerRadius = 10
        errorView.layer.masksToBounds = true
        errorView.layer.cornerCurve = .continuous
        errorView.isHidden = true
    }
    
    func handleError(_ error: Error) {
        isSubmitting = false
        confirmEmailTextField.text = ""
        CustomSwiftMessages.displayError(error)
//        errorLabel.attributedText = CustomAttributedString.errorMessage(errorText: "That didn't work.", size: 16)
//        errorView.isHidden = false
//        errorView.animation = "shake"
//        errorView.animate()
    }
}
