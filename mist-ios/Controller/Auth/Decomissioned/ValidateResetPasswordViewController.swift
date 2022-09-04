////
////  ValidateResetPasswordViewController.swift
////  mist-ios
////
////  Created by Adam Monterey on 7/7/22.
////
//
//import UIKit
//
//class ValidateResetPasswordViewController: KUIViewController, UITextFieldDelegate {
//
//    @IBOutlet weak var emailLabel: UILabel!
//    @IBOutlet weak var confirmEmailTextField: UITextField!
//    @IBOutlet weak var continueButton: UIButton!
//    @IBOutlet weak var resendButton: UIButton!
//
//    var isValidInput: Bool! {
//        didSet {
//            continueButton.isEnabled = isValidInput
//            continueButton.setNeedsUpdateConfiguration()
//        }
//    }
//    var isSubmitting: Bool = false {
//        didSet {
//            continueButton.isEnabled = !isSubmitting
//            continueButton.setNeedsUpdateConfiguration()
//        }
//    }
//    var resendState: ResendState = .notsent {
//        didSet {
//            resendButton.setNeedsUpdateConfiguration()
//        }
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        emailLabel.text! += AuthContext.email
//
//        validateInput()
//        shouldNotAnimateKUIAccessoryInputView = true
//        setupConfirmEmailTextField()
//        setupContinueButton()
//        setupResendButton()
//        setupBackButton()
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        enableInteractivePopGesture()
//    }
//
//    //MARK: - Setup
//
//    func setupConfirmEmailTextField() {
//        confirmEmailTextField.delegate = self
//        confirmEmailTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
//        confirmEmailTextField.layer.cornerRadius = 5
//
//        let xconstraints: CGFloat = 50
//        let textFieldWidth = view.frame.size.width - xconstraints
//        let numberWidth: CGFloat = 14
//        let spacing = (textFieldWidth / 7) - numberWidth
//        confirmEmailTextField.setLeftPaddingPoints(spacing)
//        confirmEmailTextField.defaultTextAttributes.updateValue(spacing, forKey: NSAttributedString.Key.kern)
//
//        confirmEmailTextField.becomeFirstResponder()
//    }
//
//    func setupResendButton() {
//        resendButton.configuration?.imagePadding = 5
//        let resendAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 12)!]
//
//        resendButton.configurationUpdateHandler = { [weak self] button in
//            switch self?.resendState {
//            case .notsent:
//                button.isEnabled = true
//                button.configuration?.showsActivityIndicator = false
//                button.configuration?.image = nil
//                button.configuration?.attributedTitle = AttributedString("resend", attributes: AttributeContainer(resendAttributes))
//            case .sending:
//                button.isEnabled = false
//                button.configuration?.showsActivityIndicator = true
//                button.configuration?.attributedTitle = AttributedString("resending", attributes: AttributeContainer(resendAttributes))
//            case .sent:
//                button.isEnabled = false
//                button.configuration?.showsActivityIndicator = false
//                button.configuration?.image = UIImage(systemName: "checkmark")
//                button.configuration?.attributedTitle = AttributedString("resent", attributes: AttributeContainer(resendAttributes))
//            case .none:
//                break
//            }
//        }
//    }
//
//    func setupContinueButton() {
//        continueButton.configurationUpdateHandler = { [weak self] button in
//
//            if button.isEnabled {
//                button.configuration = ButtonConfigs.enabledConfig(title: "continue")
//            }
//            else {
//                if !(self?.isSubmitting ?? false) {
//                    button.configuration = ButtonConfigs.disabledConfig(title: "continue")
//                }
//            }
//            button.configuration?.showsActivityIndicator = self?.isSubmitting ?? false
//        }
//    }
//
//    func setupBackButton() {
//        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
//        navigationItem.leftBarButtonItem?.tintColor = Constants.Color.mistBlack
//    }
//
//    //MARK: - User Interaction
//
//    @objc func goBack() {
//        navigationController?.popViewController(animated: true)
//    }
//
//    @IBAction func didPressedContinueButton(_ sender: Any) {
//        tryToContinue()
//    }
//
//    @IBAction func didPressedResendButton(_ sender: UIButton) {
//        resendCode()
//    }
//
//    //MARK: - TextField Delegate
//
//    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
//        validateInput()
//    }
//
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        if isValidInput {
//            tryToContinue()
//        }
//        return false
//    }
//
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        return textField.shouldChangeCharactersGivenMaxLengthOf(6, range, string)
//    }
//
//    //MARK: - Helpers
//
//    func tryToContinue() {
////        if let code = confirmEmailTextField.text {
////            isSubmitting = true
////            Task {
////                do {
////                    try await AuthAPI.validateResetPassword(email: ResetPasswordContext.email, code: code)
////                    let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.FinalizeResetPassword);
////                    self.navigationController?.pushViewController(vc, animated: true, completion: { [weak self] in
////                        self?.isSubmitting = false
////                    })
////                } catch {
////                    handleError(error)
////                }
////            }
////        }
//    }
//
//    func resendCode() {
////        resendState = .sending
////        Task {
////            do {
////                // Send another validation email
////                try await AuthAPI.requestResetPassword(email: ResetPasswordContext.email)
////            } catch {
////                handleError(error)
////            }
////            resendState = .sent
////        }
//    }
//
//    func validateInput() {
//        isValidInput = confirmEmailTextField.text?.count == 6
//    }
//
//    func handleError(_ error: Error) {
//        isSubmitting = false
//        confirmEmailTextField.text = ""
//        CustomSwiftMessages.displayError(error)
//    }
//
//}
