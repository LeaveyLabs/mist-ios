//
//  LongInputCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/23/22.
//

import UIKit

class FeedbackFormCell: UITableViewCell {

    @IBOutlet weak var textView: UITextView!
    
    func configure(delegate: UITextViewDelegate) {
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .none
        textView.delegate = delegate
        selectionStyle = .none
        textView.isSecureTextEntry = true
    }
    
}
