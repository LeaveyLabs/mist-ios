//
//  EnterPasswordViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 4/9/22.
//

import UIKit

class EnterPasswordViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBAction func didEditBeginPasswordField(_ sender: Any) {
        passwordField.text = ""
    }
    @IBAction func didEditBeginConfirmPasswordField(_ sender: Any) {
        confirmPasswordField.text = ""
    }
    
    @IBAction func didPressedContinue(_ sender: Any) {
        if let password = passwordField.text {
            if let confirmPassword = confirmPasswordField.text {
                if(password == confirmPassword) {
                    AuthContext.password = password
                    let vc = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterName);
                    self.navigationController?.pushViewController(vc, animated: true)
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
