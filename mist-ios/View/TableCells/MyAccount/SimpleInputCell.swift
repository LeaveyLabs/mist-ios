//
//  SimpleLabelTableViewCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/11.
//

import UIKit

class SimpleInputCell: UITableViewCell {
    
    enum InputType {
        case password
    }
    
    @IBOutlet weak var textField: UITextField!
    
    func configure(as: InputType, delegate: UITextFieldDelegate) {
        textField.autocorrectionType = .yes
        textField.autocapitalizationType = .none
        textField.text = ""
        textField.delegate = delegate
        selectionStyle = .none
        textField.isSecureTextEntry = true
    }
    
}
