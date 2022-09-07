//
//  TwoButtonCenteredView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/27.
//

import Foundation
import SwiftMessages

class CustomCenteredView: MessageView {
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var approveButton: UIButton!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var bottomStackView: UIStackView!

    var dismissAction: (() -> Void)!
    var approveAction: (() -> Void)!
    
    @IBAction func dismissButtonPressed() {
        dismissAction()
    }
    
    @IBAction func approveButtonPressed() {
        approveAction()
    }
    
    override func layoutSubviews() {
        approveButton.addBorders(edges: .top, color: .systemGray5, inset: 0, thickness: 1)
        dismissButton.addBorders(edges: [.top, .right], color: .systemGray5, inset: 0, thickness: 1)
    }
    
    func customConfig(approveText: String, dismissText: String) {
        let dismissFontSize: CGFloat = dismissText.length > 12 ? 15 : 17
        let dismissAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Roman, size: dismissFontSize)!]
        let approveAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: 19)!]
        approveButton.setAttributedTitle(NSAttributedString(string: approveText, attributes: approveAttributes), for: .normal)
        dismissButton.setAttributedTitle(NSAttributedString(string: dismissText, attributes: dismissAttributes), for: .normal)
        approveButton.titleLabel?.textAlignment = .center
        dismissButton.titleLabel?.textAlignment = .center
        
        
        if approveText.isEmpty {
            approveButton.isHidden = true
        }
    }
    
    func badgeConfig() {
        approveButton.isHidden = true
        dismissButton.isHidden = true
        exitButton.isHidden = false
        bottomStackView.isHidden = true //not actually neeeded
    }

}
