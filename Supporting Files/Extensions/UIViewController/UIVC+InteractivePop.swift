//
//  UIVC+InteractivePop.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/4/22.
//

import Foundation

extension UIViewController: UIGestureRecognizerDelegate {

  func disableInteractivePopGesture() {
    navigationItem.hidesBackButton = true
    navigationController?.interactivePopGestureRecognizer?.delegate = self
    navigationController?.interactivePopGestureRecognizer?.isEnabled = false
  }

  func enableInteractivePopGesture() {
    navigationItem.hidesBackButton = false
    navigationController?.interactivePopGestureRecognizer?.delegate = self
    navigationController?.interactivePopGestureRecognizer?.isEnabled = true
  }
    
}
