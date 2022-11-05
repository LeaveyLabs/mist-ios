//
//  CustomCardView.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/21/22.
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
        
        //For now, disabling dismiss button because it takes up too much space and cuts off text
        dismissButton.isHidden = true
    }

}
