//
//  SwiftMessagesBadgeView.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/6/22.
//

import Foundation
import SwiftMessages

class SwiftMessagesBadgeView: MessageView {
    @IBOutlet weak var exitButton: UIButton!

    var dismissAction: (() -> Void)!
    var approveAction: (() -> Void)!
    
    @IBAction func dismissButtonPressed() {
        dismissAction()
    }
    
    func badgeConfig() {
//        approveButton.isHidden = true
//        dismissButton.isHidden = true
        exitButton.isHidden = false
//        bottomStackView.isHidden = true //not actually neeeded
    }

}
