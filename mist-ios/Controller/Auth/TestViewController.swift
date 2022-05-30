//
//  TestViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/27.
//

import UIKit

class TestViewController: KUIViewController {
    
    @IBOutlet weak var asdf: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        asdf.becomeFirstResponder()

        // Do any additional setup after loading the view.
    }

}
