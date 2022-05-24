//
//  EnterEmailViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/29/22.
//

import UIKit

class AuthContext {
    struct AuthVariables : Codable {
        static var username: String = "";
        static var email: String = "";
        static var password: String = "";
        static var firstName: String = "";
        static var lastName: String = "";
    }
}

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}

class EnterEmailViewController: KUIViewController, UITextFieldDelegate {

    @IBOutlet weak var enterEmailField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enterEmailField.becomeFirstResponder()
        enterEmailField.clipsToBounds = true
        enterEmailField.layer.cornerRadius = 5
        enterEmailField.setLeftPaddingPoints(10)

        continueButton.isEnabled = false
        
        navigationController?.navigationBar.isHidden = true
        
        keyboardShouldDismissOnOuterTap = false //override parentVC
        enterEmailField.delegate = self
    }
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
        enterEmailField.text = ""
    }
    
    @IBAction func didPressedContinueButton(_ sender: Any) {
        tryToContinue()
    }
    
    func tryToContinue() {
        // If you've inputted an email
        if let email = enterEmailField.text {
            Task {
                do {
                    // Send a validation email
                    try await AuthAPI.registerEmail(email: email)
                    // Move to the next code view
                    AuthContext.AuthVariables.email = email
                    let vc = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterCodeViewController)
                    self.navigationController?.pushViewController(vc, animated: true)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    //MARK: - TextField
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tryToContinue()
        return false
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        print("should end editing")
//        textField.becomeFirstResponder()
        return false
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        continueButton.isEnabled = isValidEmail()
    }
    
    //MARK: - Helpers
    
    func isValidEmail() -> Bool {
        return enterEmailField.text?.suffix(8) == "@usc.edu"
    }
}
