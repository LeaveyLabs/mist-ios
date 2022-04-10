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

class EnterEmailViewController: UIViewController {

    @IBOutlet weak var enterEmailField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
        enterEmailField.text = ""
    }
    
    @IBAction func didPressedContinue(_ sender: Any) {
        // If you've inputted an email
        if let email = enterEmailField.text {
            Task {
                do {
                    // Send a validation email
                    if(try await AuthAPI.registerEmail(email: email)) {
                        // Move to the next code view
                        AuthContext.AuthVariables.email = email
                    }
                } catch {
                    print(error);
                }
            }
        }
    }
    
    
    /*
     // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
