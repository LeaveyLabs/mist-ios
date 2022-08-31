//
//  ExploreViewController+OverlayDelegate.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/30/22.
//

import Foundation

extension ExploreViewController {

    func setupWhiteStatusBar() {
        whiteStatusBar.applyMediumShadow()
        whiteStatusBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(whiteStatusBar)
        whiteStatusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        whiteStatusBar.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        whiteStatusBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        whiteStatusBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    }
    
    func handleFeedWentUp(duration: Double) {
        self.whiteStatusBar.isHidden = false
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            self.whiteStatusBar.alpha = 1
        }
    }
    
    func handleFeedWentDown(duration: Double) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            self.whiteStatusBar.alpha = 0
        } completion: { completed in
            self.whiteStatusBar.isHidden = true
        }
    }
}
