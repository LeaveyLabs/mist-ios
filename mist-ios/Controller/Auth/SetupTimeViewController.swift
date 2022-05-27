//
//  SetupTimeViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/25.
//

import UIKit

class SetupTimeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    @IBAction func didPressedContinueButton(_ sender: Any) {
        let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ChooseUsername)
        print(vc)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
