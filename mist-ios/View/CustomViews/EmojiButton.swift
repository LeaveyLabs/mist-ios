//
//  EmojiButton.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/2/22.
//

import Foundation

class EmojiButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        applyLightMediumShadow()
        setTitleColor(.black, for: .normal)
        layer.cornerRadius = 10
        layer.cornerCurve = .circular
        layer.shadowOpacity = 0
        titleLabel?.textAlignment = .left
    }
    
    override var isSelected: Bool {
        didSet {
            layer.shadowOpacity = isSelected ? 0.2 : 0
            backgroundColor = isSelected ? mistSecondaryUIColor() : nil
        }
    }
    
    var emoji: String = "" {
        didSet {
            setEmojiAndVoteCountOnButton(emoji: emoji, voteCount: self.count)
        }
    }
    
    var count: Int = 0 {
        didSet {
            setEmojiAndVoteCountOnButton(emoji: self.emoji, voteCount: count)
        }
    }

    //we cant set a certain width of the button. the button should be less wide for 1 vote, wider for 140 votes
    func setEmojiAndVoteCountOnButton(emoji: String, voteCount: Int) {
        //votecount
        let voteCountString = voteCount == 0 ? "" : " " + formattedVoteCount(Double(voteCount))
        let attributedText = NSMutableAttributedString(string: emoji + voteCountString)
        let emojiRange = (attributedText.string as NSString).range(of: emoji)
        let countRange = (attributedText.string as NSString).range(of: voteCountString)
        attributedText.setAttributes([.font: UIFont(name: Constants.Font.Medium, size: 20)!], range: emojiRange)
        attributedText.setAttributes([.font: UIFont(name: Constants.Font.Medium, size: 14)!], range: countRange)
        setAttributedTitle(attributedText, for: .normal)
    }
    
}

//EmojiTextField is the text field which is linked to ReactButton (not emoji button) which summons the emoji keyboard

class EmojiTextField: UITextField {
    
    // required for iOS 13
    override var textInputContextIdentifier: String? { "" } // return non-nil to show the Emoji keyboard ¯\_(ツ)_/¯

    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return nil
    }
    
    weak var postDelegate: PostDelegate?

    override func deleteBackward() {
        super.deleteBackward()
        postDelegate?.emojiKeyboardDidDelete()
    }
}
