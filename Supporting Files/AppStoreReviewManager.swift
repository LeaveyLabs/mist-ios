//
//  AppStoreReviewManager.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/23/22.
//

import Foundation
import StoreKit

enum AppStoreReviewManager {
    
  static func requestReviewIfAppropriate() {
      if !DeviceService.shared.hasBeenRequestedARating() {
          DeviceService.shared.showRatingRequest()
          SKStoreReviewController.requestReviewInCurrentScene()
      }
  }
    
}

extension SKStoreReviewController {
    
    public static func requestReviewInCurrentScene() {
        
        if #available(iOS 14.0, *) {if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                requestReview(in: scene)
            }
        } else {
            requestReview()
        }
        
    }
    
}
