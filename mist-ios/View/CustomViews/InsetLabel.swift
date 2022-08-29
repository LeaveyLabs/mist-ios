//
//  InsetLabel.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/24/22.
//

import Foundation

class InsetLabel: UILabel {
    
    var insets: UIEdgeInsets
    
    init(frame: CGRect, insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)) {
        self.insets = insets
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    
}
