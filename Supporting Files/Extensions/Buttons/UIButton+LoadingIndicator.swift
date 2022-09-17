//
//  UIButton+LoadingIndicator.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/10/22.
//

import Foundation

extension UIButton {
    
    static let LoadingIndicatorTag = 808404
    
    var isButtonCustomLoadingIndicatorVisible: Bool {
        get {
            return viewWithTag(UIButton.LoadingIndicatorTag) != nil
        }
    }
    
    func loadingIndicator(_ show: Bool) {
        if show {
            self.isEnabled = false
            self.alpha = 0.5
            let indicator = UIActivityIndicatorView()
            indicator.color = Constants.Color.mistBlack
            let buttonHeight = self.bounds.size.height
            let buttonWidth = self.bounds.size.width
            indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
            indicator.tag = UIButton.LoadingIndicatorTag
            self.addSubview(indicator)
            indicator.startAnimating()
        } else {
            self.imageView?.isHidden = false
            self.isEnabled = true
            self.alpha = 1.0
            if let indicator = self.viewWithTag(UIButton.LoadingIndicatorTag) as? UIActivityIndicatorView {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }
}
