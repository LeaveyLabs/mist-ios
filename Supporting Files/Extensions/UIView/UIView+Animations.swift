//
//  UIView+Animations.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/04.
//

import Foundation
import UIKit

extension UIView {
    func fadeIn(duration: TimeInterval = 0.3,
                delay: TimeInterval = 0.0,
                completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in }) {
        self.alpha = 0.0

//        UIVIew.AnimationOptions.transitionCrossDisolve
//        what do the different options do?
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .curveEaseIn,
                       animations: {
            self.isHidden = false
            self.alpha = 1.0
        }, completion: completion)
    }

    //NOTE: whenever using this function, you must set self.isHidden=true in the completion handler
    func fadeOut(duration: TimeInterval = 0.3,
                 delay: TimeInterval = 0.0,
                 completion: @escaping (Bool) -> Void) {
//        self.alpha = 1.0 what if the alpha was 0.5 before starting the fade out? you don't want to set it to 1 before the fadeout. this was causing weird behavior with post swiping

        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .transitionCrossDissolve,
                       animations: {
            self.alpha = 0.0
        }, completion: completion)
    }
}
