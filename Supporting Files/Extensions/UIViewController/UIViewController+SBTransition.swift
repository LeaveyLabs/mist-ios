//
//  UIViewController+SBTransition.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/25.
//

import Foundation

extension UIViewController {
    // Reference: https://stackoverflow.com/questions/41144523/swap-rootviewcontroller-with-animation
    func transitionToStoryboard(storyboardID: String,
                                viewControllerID: String,
                                duration: Double,
                                completion: @escaping (Bool) -> Void) {
        let sb = UIStoryboard(name: storyboardID, bundle: nil)
        let homeVC = sb.instantiateViewController(withIdentifier: viewControllerID)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let delegate = windowScene.delegate as? SceneDelegate, let window = delegate.window else {
            return
        }
        
        // Set the new rootViewController of the window.
        // Calling "UIView.transition" below will animate the swap.
        delegate.window?.rootViewController = homeVC

        // A mask of options indicating how you want to perform the animations.
        let options: UIView.AnimationOptions = .transitionCrossDissolve

        // The duration of the transition animation, measured in seconds.
        let duration: TimeInterval = duration

        
        // Creates a transition animation.
        // Though `animations` is optional, the documentation tells us that it must not be nil. ¯\_(ツ)_/¯
        UIView.transition(with: window, duration: duration, options: options, animations: {}, completion: completion)
    }
    
    func transitionToHomeAndRequestPermissions(completion: @escaping () -> Void) {
        let sb = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil)
        let homeVC = sb.instantiateViewController(withIdentifier: Constants.SBID.VC.TabBarController) as! SpecialTabBarController
        let navVC = homeVC.viewControllers![0] as! UINavigationController
        let exploreMapVC = navVC.visibleViewController! as! ExploreMapViewController
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let delegate = windowScene.delegate as? SceneDelegate, let window = delegate.window else {
            return
        }
        
        // Set the new rootViewController of the window.
        // Calling "UIView.transition" below will animate the swap.
        delegate.window?.rootViewController = homeVC

        // A mask of options indicating how you want to perform the animations.
        let options: UIView.AnimationOptions = .transitionCrossDissolve

        // The duration of the transition animation, measured in seconds.
        let duration: TimeInterval = 1

        
        // Creates a transition animation.
        // Though `animations` is optional, the documentation tells us that it must not be nil. ¯\_(ツ)_/¯
        UIView.transition(with: window, duration: duration, options: options, animations: {}) { _ in
            completion()
            exploreMapVC.handleUserLocationPermissionRequest()
        }
    }
}
