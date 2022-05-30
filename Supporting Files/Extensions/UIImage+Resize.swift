//
//  UIImage+Resize.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/26.
//

import Foundation

extension UIImage {
  func resizedImage(Size sizeImage: CGSize) -> UIImage? {
      let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: sizeImage.width, height: sizeImage.height))
      UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
      self.draw(in: frame)
      let resizedImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      self.withRenderingMode(.alwaysOriginal)
      return resizedImage
  }
}
