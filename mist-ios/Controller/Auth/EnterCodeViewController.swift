//
//  EnterCodeViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 3/29/22.
//

import UIKit

class EnterCodeViewController: UIViewController {

    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    var email:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func didPressedContinue(_ sender: Any) {
        // If you've inputted the code
        if let code = codeField.text {
            Task {
                do {
                    // Check if the code's valid
                    if(try await AuthAPI.validateEmail(email: AuthContext.AuthVariables.email, code: code)) {
                        print("attempting to proceed")
                        // If so, move onto the next screen
                        let vc = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: "WelcomeTutorialViewController");
                        self.navigationController?.pushViewController(vc, animated: true)
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
