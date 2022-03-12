//
//  RulesViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/08.
//

import UIKit

class RulesViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func understoodButtonDidPressed(_ sender: UIButton) {
        presentingViewController!.dismiss(animated: true);
    }
    
}
