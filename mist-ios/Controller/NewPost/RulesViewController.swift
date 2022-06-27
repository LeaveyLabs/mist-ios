//
//  RulesViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/08.
//

import UIKit

class RulesViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var learnMoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attributedString = NSMutableAttributedString(string: "Learn more about how we moderate content here.")
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemBlue, range: .init(location: 41, length: 4))
        learnMoreLabel.attributedText = attributedString
    }
    
    @IBAction func learnMoreButtonDidPressed(_ sender: UIButton) {
        guard let url = URL(string: "https://www.getmist.app/content-guideines") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func understoodButtonDidPressed(_ sender: UIButton) {
        presentingViewController!.dismiss(animated: true)
    }
    
}
