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
        
        agreementLabel.isHidden = true
        validateInput()
        isAuthKUIView = true
        setupErrorLabel()
        setupPopGesture()
        setupConfirmEmailTextField()
        setupContinueButton()
        setupResendButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print(confirmEmailTextField.frame.size.width)
    }
    
    //MARK: - Setup
    
    func setupConfirmEmailTextField() {
        confirmEmailTextField.delegate = self
        confirmEmailTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        confirmEmailTextField.layer.cornerRadius = 5
        confirmEmailTextField.setLeftPaddingPoints(20)
        confirmEmailTextField.defaultTextAttributes.updateValue(34, forKey: NSAttributedString.Key.kern)
        confirmEmailTextField.becomeFirstResponder()
    }
    
    func setupResendButton() {
        resendButton.configuration?.imagePadding = 5
        
        resendButton.configurationUpdateHandler = { [weak self] button in
            switch self?.resendState {
            case .notsent:
                button.isEnabled = true
                button.configuration?.showsActivityIndicator = false
                button.configuration?.image = nil
                button.configuration?.title = "Resend"
            case .sending:
                button.isEnabled = false
                button.configuration?.showsActivityIndicator = true
                button.configuration?.title = "Resending"
            case .sent:
                button.isEnabled = false
                button.configuration?.showsActivityIndicator = false
                button.configuration?.image = UIImage(systemName: "checkmark")
                button.configuration?.title = "Resent"
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
                print(error)
            }
            resendState = .sent
        }
    }
    
    func validateInput() {
        isValidInput = confirmEmailTextField.text?.count == 6
    }
}

// Error View functions
extension ConfirmEmailViewController {
    
    func setupErrorLabel() {
        errorView.layer.cornerRadius = 10
        errorView.layer.masksToBounds = true
        errorView.isHidden = true
        errorView.layer.cornerCurve = .continuous
    }
    
    func handleError(_ error: Error) {
        isSubmitting = false
        confirmEmailTextField.text = ""
        errorLabel.attributedText = CustomAttributedString.errorMessage(errorText: "That didn't work.", size: 16)
        errorView.isHidden = false
        errorView.animation = "shake"
        errorView.animate()
    }
}

extension ConfirmEmailViewController: UIGestureRecognizerDelegate {
    
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
