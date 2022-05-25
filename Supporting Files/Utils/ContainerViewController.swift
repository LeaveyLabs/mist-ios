//
//  ContainerViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/25.
//

import Foundation
import UIKit

/*
 * Since swapping windows and/or root view controllers is usually badly animated, it is recommended to set a container view controller as a root view controller, and put/swap controllers (together with transitions) - https://github.com/malcommac/UIWindowTransitions/issues/7, you can see an example of a bug here - https://stackoverflow.com/a/27153956
 * Also it's easier to manage rotations with root transition controller, and other custom animations on child controllers (example of transition controller is here https://gist.github.com/xjones/1394947)
 * Another approach is just to present over current views and do not bother about swapping root view controllers (observers must be unregistered properly then)
 * And for a question on how to preserve child view's orientation while root view must rotate - https://stackoverflow.com/a/38979427
 */

final class ContainerViewController: UIViewController {
    fileprivate var containerView: UIView?
    fileprivate var __shouldAutorotate = true
    fileprivate var __supportedInterfaceOrientations: UIInterfaceOrientationMask = [.portrait]
    
    var currentViewController: UIViewController?
    
    convenience init(with viewController: UIViewController,
            shouldAutorotate: Bool,
            supportedInterfaceOrientations: UIInterfaceOrientationMask) {
        self.init()
        __shouldAutorotate = shouldAutorotate
        __supportedInterfaceOrientations = supportedInterfaceOrientations
        currentViewController = viewController
    }
    
    // note that the window’s root view controller does not react to edgesForExtendedLayout property
    override func loadView() {
        let __view = UIView(frame: UIScreen.main.bounds)
        __view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view = __view
        
        if let currentController = currentViewController {
            self.add(child: currentController, into: __view)
        }
    }
    
    // the topmost view controller always decides if we should and how we should autorotate
    
    override var shouldAutorotate: Bool {
        get {
            return __shouldAutorotate
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return __supportedInterfaceOrientations
        }
    }
    
    // orientation callbacks will be propagated automatically if child view controller's view is visible

    /*
     * This will invoke loadView() for view controller passed if it wasn't already invoked.
     */
    func transition(to viewController: UIViewController, with options: UIView.AnimationOptions? = nil) {
        viewController.view.frame = self.view.frame
        
        if let animationOptions = options {
            UIView.transition(with: self.view, duration: 0.3, options: animationOptions, animations: { [unowned self] in
                if let currentController = self.currentViewController {
                    self.remove(child: currentController)
                    self.add(child: viewController, into: self.view)
                    self.currentViewController = nil
                }
            }) { [unowned self] finished in
                // avoid overriding child view controller if optional unwrap failed in previous closure
                if (finished && nil == self.currentViewController) {
                    self.currentViewController = viewController
                }
            }
        } else {
            if let currentController = self.currentViewController {
                remove(child: currentController)
                add(child: viewController, into: self.view)
                currentViewController = viewController
            }
        }
    }
    
    // implement your custom transition animations here
}

extension UIViewController {
    func add(child controller: UIViewController, into aView: UIView) {
        self.addChild(controller)
        aView.addSubview(controller.view)
        controller.didMove(toParent: self)
    }

    func remove(child controller: UIViewController) {
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
    }
}
