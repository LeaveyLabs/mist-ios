//
//  UIImage+Blur.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/10.
//

import Foundation


extension UIImage {
        
    func blur() -> UIImage {
        let currentFilter = CIFilter(name: "CIGaussianBlur")
        let beginImage = CIImage(image: self)
        currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter!.setValue(58, forKey: kCIInputRadiusKey)

        let cropFilter = CIFilter(name: "CICrop")
        cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
        cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")

        let output = cropFilter!.outputImage
        let cgimg = CIContext(options: nil).createCGImage(output!, from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        return processedImage
    }

}
