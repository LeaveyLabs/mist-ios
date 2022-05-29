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

}
