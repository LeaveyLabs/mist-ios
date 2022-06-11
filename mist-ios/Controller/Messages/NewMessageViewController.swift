//
//  DmViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/12.
//

import UIKit

class NewMessageViewController: UIViewController {

    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBOutlet weak var authorProfilePic: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authorProfilePic.image = authorProfilePic.image!.blur()
    }

    @IBAction func xButtonDidPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
    
    @IBAction func sendButtonDidPressed(_ sender: UIBarButtonItem) {
        
    }
}

var context = CIContext(options: nil)
