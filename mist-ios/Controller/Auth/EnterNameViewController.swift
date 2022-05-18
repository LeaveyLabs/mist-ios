//
//  EnterNameViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 4/9/22.
//

import UIKit

class EnterNameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    
    @IBAction func didEditBeginFirstName(_ sender: Any) {
        firstNameField.text = ""
    }
    
    @IBAction func didEditBeginLastName(_ sender: Any) {
        lastNameField.text = ""
    }
    
    @IBAction func didPressedContinue(_ sender: Any) {
        if let firstName = firstNameField.text, let lastName = lastNameField.text {
            AuthContext.AuthVariables.firstName = firstName
            AuthContext.AuthVariables.lastName = lastName
            Task {
                do {
                    try await UserService.singleton.createAccount(
                        userId: String(NSUUID().uuidString.prefix(10)),
                        username: AuthContext.AuthVariables.username,
                        password: AuthContext.AuthVariables.password,
                        email: AuthContext.AuthVariables.email,
                        firstName: AuthContext.AuthVariables.firstName,
                        lastName: AuthContext.AuthVariables.lastName)
                    let vc = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterProfilePictureViewController)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                catch {
                    print(error)
                }
            }
        }
    }

}
