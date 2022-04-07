//
//  OkViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class MoreViewController: UIViewController {

    //TODO: make drop down arrow image go completely behind sortbybutton in postviewcontroller
    
    @IBOutlet weak var containingView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.layer.cornerRadius = 5
        containingView.layer.cornerRadius = 15
        //containingView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Only curve top corners
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func shareButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func reportButton(_ sender: UIButton) {
        dismiss(animated: true)

    }
}
