//
//  UIImageView+ProfilePic.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/20/22.
//

import Foundation

extension UIImageView {
    
    func becomeProfilePicImageView(with profilePic: UIImage?) {
        image = profilePic
        contentMode = .scaleAspectFill
        becomeRound()
        if let buttonSuperview = superview as? UIButton {
            buttonSuperview.setImage(profilePic, for: .normal) //the old button type requires this method of setting the image
            buttonSuperview.becomeRound()
        }
    }
    
}
