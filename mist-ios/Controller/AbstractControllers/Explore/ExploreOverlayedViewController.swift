//
//  NewExploreViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/30/22.
//

import Foundation
import OverlayContainer
import UIKit

class ExploreOverlayedViewController: UIViewController {

    enum OverlayNotch: Int, CaseIterable {
        case minimum, maximum
    }

    @IBOutlet var overlayContainerView: UIView!
    @IBOutlet var backgroundView: UIView!
    var exploreVC: ExploreViewController!
    var feedOverlayVC: FeedOverlayViewController!
    var overlayController = OverlayContainerViewController()
    
    var currentNotch: OverlayNotch = .minimum

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        overlayController.delegate = self
        exploreVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Home) as? ExploreViewController
        feedOverlayVC = FeedOverlayViewController.create(postDelegate: exploreVC)
//        let feedNav = UINavigationController(rootViewController: feedOverlayVC)
//        let mapNav = UINavigationController(rootViewController: exploreVC)
        overlayController.viewControllers = [feedOverlayVC]
        addChild(exploreVC, in: backgroundView)
        addChild(overlayController, in: overlayContainerView)
        addFloatingButton()
        
        let notchTap = UITapGestureRecognizer(target: self, action: #selector(didTapFeedNotch))
        feedOverlayVC.notchView.addGestureRecognizer(notchTap)
    }
    
    @objc func didTapFeedNotch() {
        switch currentNotch {
        case .minimum:
            overlayController.moveOverlay(toNotchAt: OverlayNotch.maximum.rawValue, animated: true, completion: nil)
        case .maximum:
            overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: true, completion: nil)
        }
    }

    // MARK: - Private

    private func notchHeight(for notch: OverlayNotch, availableSpace: CGFloat) -> CGFloat {
        switch notch {
        case .maximum:
            return availableSpace
        case .minimum:
            return 65
        }
    }
}

extension ExploreOverlayedViewController: OverlayContainerViewControllerDelegate {
    
    // MARK: - OverlayContainerViewControllerDelegate

    func numberOfNotches(in containerViewController: OverlayContainerViewController) -> Int {
        return OverlayNotch.allCases.count
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        heightForNotchAt index: Int,
                                        availableSpace: CGFloat) -> CGFloat {
        let notch = OverlayNotch.allCases[index]
        return notchHeight(for: notch, availableSpace: availableSpace)
    }
    
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, willMoveOverlay overlayViewController: UIViewController, toNotchAt index: Int) {
        guard let notch = OverlayNotch.init(rawValue: index) else { return }
        switch notch {
        case .maximum:
            feedOverlayVC.handleFeedWentUp(duration: 0.3)
            exploreVC.handleFeedWentUp(duration: 0.3)
        case .minimum:
            feedOverlayVC.handleFeedWentDown(duration: 0.3)
            exploreVC.handleFeedWentDown(duration: 0.3)
        }
    }
    
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, didMoveOverlay overlayViewController: UIViewController, toNotchAt index: Int) {
        guard let notch = OverlayNotch.init(rawValue: index) else { return }
        currentNotch = notch
    }
    
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, willStartDraggingOverlay overlayViewController: UIViewController) {
        if currentNotch == .maximum {
            feedOverlayVC.handleFeedWentDown(duration: 0.3)
            exploreVC.handleFeedWentDown(duration: 0.3)
        }
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        scrollViewDrivingOverlay overlayViewController: UIViewController) -> UIScrollView? {
        return (overlayViewController as? FeedOverlayViewController)?.feed
    }
    
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        shouldStartDraggingOverlay overlayViewController: UIViewController,
                                        at point: CGPoint,
                                        in coordinateSpace: UICoordinateSpace) -> Bool {
        guard let header = (overlayViewController as? FeedOverlayViewController)?.notchView else {
            return false
        }
        let convertedPoint = coordinateSpace.convert(point, to: header)
        return header.bounds.contains(convertedPoint)
    }
}

extension UIViewController {
    func addChild(_ child: UIViewController, in containerView: UIView) {
        guard containerView.isDescendant(of: view) else { return }
        addChild(child)
        containerView.addSubview(child.view)
        child.view.pinToSuperview()
        child.didMove(toParent: self)
    }

    func removeChild(_ child: UIViewController) {
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
    }
}

extension UIView {
    func pinToSuperview(with insets: UIEdgeInsets = .zero, edges: UIRectEdge = .all) {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        if edges.contains(.top) {
            topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top).isActive = true
        }
        if edges.contains(.bottom) {
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom).isActive = true
        }
        if edges.contains(.left) {
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left).isActive = true
        }
        if edges.contains(.right) {
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.right).isActive = true
        }
    }
}
