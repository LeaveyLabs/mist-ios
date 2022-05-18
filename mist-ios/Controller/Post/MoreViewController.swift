//
//  OkViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class MoreViewController: SheetViewController {
    
    //TODO: make drop down arrow image go completely behind sortbybutton in postviewcontroller
    
    @IBOutlet weak var closeButton: UIButton!
    var delegate: PostCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.layer.cornerRadius = 5
        setupSheet(prefersGrabberVisible: false,
                   detents: [Constants.Detents.s],
                   bgInteractionEnabled: false)
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
        //https://developer.apple.com/library/archive/technotes/tn2444/_index.html
        //TODO: use Open Graph protocols on our website for a Rich imessage display
    @IBAction func shareButton(_ sender: UIButton) {
        dismiss(animated: true) { [self] in
            delegate?.presentShareActivityVC()
        }
    }
    
    func activityViewDidDismiss() {
        self.dismiss(animated: true)
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func reportButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
