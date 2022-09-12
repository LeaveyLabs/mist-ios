//
//  UIViewController+MistShareActivity.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

protocol ShareActivityDelegate {
    func presentShareActivityVC()
}

extension UIViewController {
    
    func presentMistShareActivity() {
        let objectsToShare: [Any] = [Constants.downloadLink]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        present(activityVC, animated: true)
    }
}
