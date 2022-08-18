//
//  UIViewController+Window.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/18/22.
//

import Foundation

extension UIViewController {
    //not thoroughly tested for proper functionality
    var rootViewController: UIViewController? {
        get {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let delegate = windowScene.delegate as? SceneDelegate, let window = delegate.window else { return nil }
            return window.rootViewController
        }
    }
    var window: UIWindow? {
        get {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let delegate = windowScene.delegate as? SceneDelegate, let window = delegate.window else { return nil }
            return window
        }
    }
    
}
