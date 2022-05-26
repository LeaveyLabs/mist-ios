//
//  EnterUsernameViewController.swift
//  mist-ios
//
//  Created by Kevin Sun on 4/9/22.
//

import UIKit

class EnterUsernameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBAction func didPressedContinue(_ sender: Any) {
        // If the username field is not empty ...
        if let username = usernameField.text {
            AuthContext.username = username
            // Move onto the next screen
            let vc = UIStoryboard(name: "Auth", bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.CreatePassword);
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
