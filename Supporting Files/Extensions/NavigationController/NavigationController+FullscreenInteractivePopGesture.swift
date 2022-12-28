//
//  NavigationController+ExpandInteractivePopGesture.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/18/22.
//

import UIKit

//https://stackoverflow.com/questions/35388985/how-can-i-implement-drag-right-to-dismiss-a-view-controller-thats-in-a-naviga/57487724#57487724
public extension UINavigationController {
  func fullscreenInteractivePopGestureRecognizer(delegate: UIGestureRecognizerDelegate) {
    guard
      let popGestureRecognizer = interactivePopGestureRecognizer,
      let targets = popGestureRecognizer.value(forKey: "targets") as? NSMutableArray,
      let gestureRecognizers = view.gestureRecognizers,
      targets.count > 0
    else { return }

    if viewControllers.count == 1 {
      for recognizer in gestureRecognizers where recognizer is PanDirectionGestureRecognizer {
        view.removeGestureRecognizer(recognizer)
        popGestureRecognizer.isEnabled = false
        recognizer.delegate = nil
      }
    } else {
      if gestureRecognizers.count == 1 {
        let gestureRecognizer = PanDirectionGestureRecognizer(axis: .horizontal, direction: .right)
//        gestureRecognizer.cancelsTouchesInView = false //not sure what this does ngl
        gestureRecognizer.setValue(targets, forKey: "targets")
//        gestureRecognizer.require(toFail: popGestureRecognizer) the original author of this code wrote in this line, but i don't think it's actually necessary. it seems to prevent the gesture from being recognized sometimes
        gestureRecognizer.delegate = delegate
        popGestureRecognizer.isEnabled = true

        view.addGestureRecognizer(gestureRecognizer)
      }
    }
  }
}
