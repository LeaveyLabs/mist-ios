//
//  Experimental.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/17/22.
//

import Foundation


extension ExploreViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animatedTransitioning = FadeViewControllerTransition()
        animatedTransitioning.fadeOut = false
        return animatedTransitioning
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animatedTransitioning = FadeViewControllerTransition()
        animatedTransitioning.fadeOut = true
        return animatedTransitioning
    }
}


class FadeViewControllerTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var fadeOut: Bool = false
    
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        if fadeOut {
            animateFadeOut(using: transitionContext)
            return
        }
        
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        print(toViewController)
        transitionContext.containerView.addSubview(toViewController.view)
        toViewController.view.alpha = 0.0
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toViewController.view.alpha = 1.0
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    func animateFadeOut(using transitionContext: UIViewControllerContextTransitioning) {
        
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        transitionContext.containerView.insertSubview(toViewController.view, belowSubview: fromViewController.view)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromViewController.view.alpha = 0.0
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
