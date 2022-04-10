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

        // Do any additional setup after loading the view.
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
        if let firstName = firstNameField.text {
            if let lastName = lastNameField.text {
                AuthContext.AuthVariables.firstName = firstName
                AuthContext.AuthVariables.lastName = lastName
                Task {
                    do {
                        if(try await AuthAPI.createUser(email: AuthContext.AuthVariables.email, username: AuthContext.AuthVariables.username, password: AuthContext.AuthVariables.password, first_name: AuthContext.AuthVariables.firstName, last_name: AuthContext.AuthVariables.lastName)) {
                            
                        }
                    } catch {
                        print(error);
                    }
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
