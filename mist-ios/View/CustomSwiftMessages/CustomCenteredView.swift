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
        let dismissAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 18)!]
        let approveAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: 18)!]
        approveButton.configuration?.attributedTitle = AttributedString(approveText, attributes: AttributeContainer(approveAttributes))
        dismissButton.configuration?.attributedTitle = AttributedString(dismissText, attributes: AttributeContainer(dismissAttributes))
        
        if approveText.isEmpty {
            approveButton.isHidden = true
        }
    }

}
