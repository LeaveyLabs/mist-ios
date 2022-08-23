//
//  UIView+FindVC.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/01.
//

import Foundation

extension UIView {
    func parentViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.parentViewController()
        } else {
            return nil
        }
    }
}
