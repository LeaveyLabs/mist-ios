//
//  UIViewController+ShareImage.swift
//  mist-ios
//
//  Created by Adam Monterey on 10/10/22.
//

import Foundation

extension UIViewController {
    
    func shareImage(imageToShare: UIImage, url: URL, completion: @escaping () -> Void? = {() -> Void in } ) {
        let activityViewController = UIActivityViewController(activityItems: [imageToShare, url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // present the view controller
        self.present(activityViewController, animated: true) {
            completion()
        }
    }
    
}
