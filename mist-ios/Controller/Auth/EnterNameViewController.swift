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
            AuthContext.firstName = firstName
            AuthContext.lastName = lastName
            Task {
                do {
                    try await UserService.singleton.createUser(
                        username: AuthContext.username,
                        firstName: AuthContext.firstName,
                        lastName: AuthContext.lastName,
                        picture: nil,
                        email: AuthContext.email,
                        password: AuthContext.password)
                    let vc = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterProfilePicture)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                catch {
                    print(error)
                }
            }
        }
    }

}
