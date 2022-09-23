//
//  EnterEmailViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/29/22.
//

import UIKit

class EnterEmailViewController: KUIViewController, UITextFieldDelegate {

    @IBOutlet weak var enterEmailTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
     
    var isValidInput: Bool! {
        didSet {
            continueButton.isEnabled = isValidInput
        }
    }
    var isSubmitting: Bool = false {
        didSet {
            continueButton.setTitle(isSubmitting ? "" : "continue", for: .normal)
            continueButton.loadingIndicator(isSubmitting)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isValidInput = false
        validateInput()
        shouldNotAnimateKUIAccessoryInputView = true
        setupPopGesture()
        setupEnterEmailTextField()
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
        enterEmailTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disableInteractivePopGesture()
    }
    
    //MARK: - Setup
    
    func setupEnterEmailTextField() {
        enterEmailTextField.delegate = self
        enterEmailTextField.layer.cornerRadius = 5
        enterEmailTextField.setLeftAndRightPadding(10)
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
    }
    
    //MARK: - User Interaction
    
    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didPressedContinueButton(_ sender: Any) {
        tryToContinue()
    }
    
    //MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //people's thumbs get in the way
//        if isValidInput {
//            tryToContinue()
//        }
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
        detectAutoFill(textField: textField, range: range, string: string)
        return true
    }
    
    //MARK: - Helpers
    
    func tryToContinue() {
        if let email = enterEmailTextField.text?.lowercased() {
            isSubmitting = true
            Task {
                do {
                    try await AuthAPI.registerEmail(email: email)
                    AuthContext.email = email
                    let vc = ConfirmCodeViewController.create(confirmMethod: .signupEmail)
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
        enterEmailTextField.text = ""
        validateInput()
        CustomSwiftMessages.displayError(error)
    }
    
    func validateInput() {
        isValidInput = (enterEmailTextField.text?.contains("@usc.edu"))! || enterEmailTextField.text == "adamvnovak@protonmail.com"
//        isValidInput = enterEmailTextField.text?.suffix(8).lowercased() == "@usc.edu"
    }
    
    //MARK: DetectAutoFill

    private var fieldPossibleAutofillReplacementAt: Date?
    private var fieldPossibleAutofillReplacementRange: NSRange?
    func detectAutoFill(textField: UITextField, range: NSRange, string: String) {
        // To detect AutoFill, look for two quick replacements. The first replaces a range with a single space
        // (or blank string starting with iOS 13.4).
        // The next replaces the same range with the autofilled content.
        if string == " " || string == "" {
            self.fieldPossibleAutofillReplacementRange = range
            self.fieldPossibleAutofillReplacementAt = Date()
        } else {
            if fieldPossibleAutofillReplacementRange == range, let replacedAt = self.fieldPossibleAutofillReplacementAt, Date().timeIntervalSince(replacedAt) < 0.1 {
                DispatchQueue.main.async { [self] in
                    tryToContinue()
                }
            }
            self.fieldPossibleAutofillReplacementRange = nil
            self.fieldPossibleAutofillReplacementAt = nil
        }
    }
    
}

// UIGestureRecognizerDelegate (already inherited in an extension)

extension EnterEmailViewController {
    
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
