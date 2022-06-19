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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableInteractivePopGesture()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        enableInteractivePopGesture()
    }
    
    @IBAction func didPressedContinueButton(_ sender: Any) {
        let vc = UIStoryboard(name: Constants.SBID.SB.Auth, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ChooseUsername)
        navigationController?.pushViewController(vc, animated: true)
    }
}
