//
//  CustomCardView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/08.
//

import Foundation
import SwiftMessages

class CustomCardView: MessageView {
    
    @IBOutlet weak var dismissButton: UIButton!

    var dismissAction: (() -> Void)!
    
    @IBAction func dismissButtonPressed() {
        dismissAction()
    }
    
    override func layoutSubviews() {
        dismissButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        dismissButton.setTitle("", for: .normal)
    }

}
