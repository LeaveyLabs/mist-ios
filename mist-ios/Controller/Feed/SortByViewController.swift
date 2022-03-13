//
//  OkViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class SortByViewController: UIViewController {

    //TODO: make drop down arrow image go completely behind sortbybutton in postviewcontroller
    
    @IBOutlet weak var containingView: UIView!
    @IBOutlet weak var bestSortButton: MistUIButton!
    @IBOutlet weak var topSortButton: MistUIButton!
    @IBOutlet weak var newSortButton: MistUIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        containingView.layer.cornerRadius = 10
        containingView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Only curve top corners
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func bestButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func topButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func newButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)

    }
}
