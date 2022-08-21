//
//  InputBarAccessoryView+.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/18/22.
//

import Foundation
import InputBarAccessoryView

extension InputBarAccessoryView {
    
    func configureForCommenting() {
        shouldAnimateTextDidChangeLayout = true
        maxTextViewHeight = 110 //max of 3 lines with the given font
        inputTextView.keyboardType = .twitter
        inputTextView.placeholder = COMMENT_PLACEHOLDER_TEXT
        inputTextView.font = UIFont(name: Constants.Font.Medium, size: 16) //from 17
        inputTextView.placeholderLabel.font = UIFont(name: Constants.Font.Medium, size: 16) //from 17
        inputTextView.placeholderTextColor = .systemGray
//        inputBar.backgroundView.backgroundColor = UIColor(hex: "F8F8F8")
//        inputBar.shouldForceTextViewMaxHeight
        separatorLine.height = 0.5
        
        //Middle
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 45)
        inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 45)
        inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        inputTextView.layer.borderColor = UIColor.systemGray2.cgColor
        inputTextView.tintColor = mistUIColor()
        inputTextView.backgroundColor = .systemGray6
        inputTextView.layer.borderWidth = 0.5
        inputTextView.layer.cornerRadius = 16.0
        inputTextView.layer.masksToBounds = true
        inputTextView.autocorrectionType = .no
        middleContentViewPadding.right = -45 //extends the inputbar to the right
        
        //Right
        sendButton.title = "Post"
        sendButton.setTitleColor(.lightGray, for: .disabled)
        sendButton.setTitleColor(mistUIColor(), for: .normal)
        sendButton.setTitleColor(mistUIColor().withAlphaComponent(0.4), for: .highlighted)
        sendButton.setSize(CGSize(width: 45, height: 40), animated: false) //to increase height
        setRightStackViewWidthConstant(to: 45, animated: false)
        setStackViewItems([sendButton, InputBarButtonItem.fixedSpace(10)], forStack: .right, animated: false)
        sendButton.isHidden = true

        //Left
        let inputAvatar = InputAvatar(frame: CGRect(x: 0, y: 0, width: 40, height: 40), profilePic: UserService.singleton.getProfilePic())
        setLeftStackViewWidthConstant(to: 48, animated: false)
        setStackViewItems([inputAvatar, InputBarButtonItem.fixedSpace(8)], forStack: .left, animated: false)
    }
    
    func configureForChatting() {
        //iMessage
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 36)
        inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 36)
        separatorLine.height = 0
        
        //Center
        inputTextView.layer.borderWidth = 0.5
        inputTextView.layer.borderColor = UIColor.systemGray4.cgColor
        inputTextView.tintColor = mistUIColor()
        inputTextView.backgroundColor = .lightGray.withAlphaComponent(0.1)
        inputTextView.layer.cornerRadius = 16.0
        inputTextView.layer.masksToBounds = true
        inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        shouldAnimateTextDidChangeLayout = true
        maxTextViewHeight = 144 //max of 6 lines with the given font
        if let middleContentView = middleContentView, middleContentView != inputTextView {
            middleContentView.removeFromSuperview()
            middleContentView.layer.shadowOpacity = 0
            setMiddleContentView(inputTextView, animated: false)
        }

        //Right
        setRightStackViewWidthConstant(to: 38, animated: false)
        sendButton.setSize(CGSize(width: 36, height: 36), animated: false)
        setStackViewItems([sendButton, InputBarButtonItem.fixedSpace(2)], forStack: .right, animated: false)
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 4, right: 2)
        sendButton.setImage(UIImage(named: "enabled-send-button"), for: .normal)
        sendButton.title = nil
        sendButton.becomeRound()
    }
    
    func configureForChatPrompt(chatView: WantToChatView) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 0)
        separatorLine.isHidden = true
        setRightStackViewWidthConstant(to: 0, animated: false)
        setMiddleContentView(chatView, animated: false)
    }
}
