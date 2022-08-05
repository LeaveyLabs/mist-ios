//
//  InputAvatar.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/4/22.
//

import Foundation
import InputBarAccessoryView

class InputAvatar: UIImageView, InputItem {
    
    private var size: CGSize = CGSize(width: 20, height: 20) {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return size
    }
    
    var inputBarAccessoryView: InputBarAccessoryView?
    var parentStackViewPosition: InputStackView.Position?
    
    init(frame: CGRect, profilePic: UIImage) {
        super.init(frame: frame)
        size = frame.size
        becomeProfilePicImageView(with: profilePic)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textViewDidChangeAction(with textView: InputTextView) { }
    func keyboardSwipeGestureAction(with gesture: UISwipeGestureRecognizer) { }
    func keyboardEditingEndsAction() { }
    func keyboardEditingBeginsAction() { }
}
