//
//  UIImageView+Initials.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/7/22.
//

import Foundation

public extension UIImageView {

    func addInitials(first: String, second: String, font: UIFont, textColor: UIColor, backgroundColor: UIColor? = nil) {
        if let color = backgroundColor {
            image = color.image(.init(width: self.frame.size.width * 2, height: self.frame.size.height * 2))
        }
        let initials = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
        initials.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
        initials.textAlignment = .center
        initials.text = first + "" + second
        initials.font = font
        initials.textColor = textColor
        self.addSubview(initials)
    }
}
