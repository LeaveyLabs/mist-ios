//
//  ChatMoreViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

class ChatMoreViewController: CustomSheetViewController {
        
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.layer.cornerRadius = 5
        setupSheet(prefersGrabberVisible: false,
                   detents: [._detent(withIdentifier: "s", constant: 160)],
                   largestUndimmedDetentIdentifier: nil)
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func blockButton(_ sender: UIButton) {
        dismiss(animated: true)
        
        //present a swift messages confirming if they want to hide the conversation or not
        //then, finish up
        //handle block depending on response to swift messages
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func weMetButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
