//
//  UIScrollView+ToTop.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/03.
//

import Foundation

extension UIScrollView {
    func scrollToTop() {
        let desiredOffset = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(desiredOffset, animated: true)
        
//        setContentOffset(.zero, animated: true)
        //not sure if this above is any different^?
   }
}

extension UIScrollView {
   func scrollToBottom(animated: Bool) {
     if self.contentSize.height < self.bounds.size.height { return }
     let bottomOffset = CGPoint(x: 0, y: self.contentSize.height - self.bounds.size.height)
     self.setContentOffset(bottomOffset, animated: animated)
  }
}
