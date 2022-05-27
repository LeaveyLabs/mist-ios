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
        navigationItem.setHidesBackButton(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    @IBAction func didPressedContinueButton(_ sender: Any) {
        let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ChooseUsername)
        print(vc)
        navigationController?.pushViewController(vc, animated: true)
    }
}
