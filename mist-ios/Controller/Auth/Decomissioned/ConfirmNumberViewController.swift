//
//  EnterCodeViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/29/22.
//

import UIKit

class ConfirmNumberViewController: KUIViewController, UITextFieldDelegate {

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var confirmNumberTextField: UITextField!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberLabel.text! += AuthContext.phoneNumber.asNationalPhoneNumber ?? AuthContext.phoneNumber
        validateInput()
        shouldNotAnimateKUIAccessoryInputView = true
        setupConfirmEmailTextField()
        setupContinueButton()
        setupResendButton()
    }
    
    //MARK: - Setup
    
    func setupConfirmEmailTextField() {
        confirmNumberTextField.delegate = self
        confirmNumberTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        confirmNumberTextField.layer.cornerRadius = 5
        let xconstraints: CGFloat = 50
        let textFieldWidth = view.frame.size.width - xconstraints
        let numberWidth: CGFloat = 14
        let spacing = (textFieldWidth / 7) - numberWidth
        confirmNumberTextField.setLeftPaddingPoints(spacing)
        confirmNumberTextField.defaultTextAttributes.updateValue(spacing, forKey: NSAttributedString.Key.kern)
        
        confirmNumberTextField.becomeFirstResponder()
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
        guard let code = confirmNumberTextField.text else { return }
        isSubmitting = true
        Task {
            do {
                try await PhoneNumberAPI.validateNewPhoneNumber(phoneNumber: AuthContext.phoneNumber, code: code)
                let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterBios)
                self.navigationController?.pushViewController(vc, animated: true, completion: { [weak self] in
                    self?.isSubmitting = false
                })
            } catch {
                handleError(error)
            }
        }
    }
    
    func resendCode() {
        resendState = .sending
        Task {
            do {
                // Send another validation email
                try await PhoneNumberAPI.registerNewPhoneNumber(email: AuthContext.email, phoneNumber: AuthContext.phoneNumber)
            } catch {
                handleError(error)
            }
            resendState = .sent
        }
    }
    
    func validateInput() {
        isValidInput = confirmNumberTextField.text?.count == 6
        if isValidInput {
            tryToContinue()
        }
    }
    
    func handleError(_ error: Error) {
        isSubmitting = false
        CustomSwiftMessages.displayError(error)
    }
}