//
//  NewExploreViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/30/22.
//

import Foundation
import OverlayContainer
import UIKit

class ExploreParentViewController: UIViewController, OverlayContainerViewControllerDelegate {
    
    enum OverlayNotch: Int, CaseIterable {
        case hidden, minimum, maximum
    }

    //MARK: - Properties
    
    //Overlay
    @IBOutlet var overlayContainerView: UIView!
    @IBOutlet var backgroundView: UIView!
    var exploreMapVC: ExploreMapViewController!
    var exploreFeedVC: ExploreFeedViewController!
    var overlayController = OverlayContainerViewController()
    var currentNotch: OverlayNotch = .minimum
    
    //PostDelegate
//    var loadAuthorProfilePicTasks: [Int: Task<FrontendReadOnlyUser?, Never>] = [:]
    var keyboardHeight: CGFloat = 0 //emoji keyboard autodismiss flag
    var isKeyboardForEmojiReaction: Bool = false
    var reactingPostIndex: Int? //for scrolling to the right index on the feed when react keyboard raises
    
    var isProgrammaticallyMovingOverlay: Bool = false

    //ExploreChildDelegate
    var feedPosts: [Post] {
        PostService.singleton.getExploreFeedPosts()
    }
    var mapPosts: [Post] {
        PostService.singleton.getAllExploreMapPosts()
    }
    
    var isFirstLoad = true

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOverlay()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isFirstLoad = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
        
        //Emoji keyboard autodismiss notification
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillDismiss(sender:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    func reloadNewMapPostsIfNecessary() {
        fatalError("requires subclass implementation")
    }
    
    func reloadNewFeedPostsIfNecessary() {
        fatalError("requires subclass implementation")
    }
    
    func handleUpdatedExploreFilter() {
        fatalError("requires subclass implementation")
    }
    
    // MARK: - OverlayContainer
    
    func setupOverlay() {
        overlayController.delegate = self
        exploreMapVC = ExploreMapViewController.create(postDelegate: self, exploreDelegate: self)
        exploreFeedVC = ExploreFeedViewController.create(postDelegate: self, exploreDelegate: self)
        overlayController.viewControllers = [exploreFeedVC]
        addChild(exploreMapVC, in: backgroundView)
        addChild(overlayController, in: overlayContainerView)
        let notchTap = UITapGestureRecognizer(target: self, action: #selector(didTapFeedNotch))
        exploreFeedVC.notchView.addGestureRecognizer(notchTap)
    }
    
    var isPerformingDemo = false
    func performFeedDemoAnimation() {
        isPerformingDemo = true
        UIView.animate(withDuration: 1.5, delay: 0, options: [.curveLinear, .allowAnimatedContent, .allowUserInteraction]) {
            self.overlayContainerView.transform = CGAffineTransform(translationX: 0, y: -200)
        } completion: { finished in
            UIView.animate(withDuration: 0.75,
                           delay: 0,
                           usingSpringWithDamping: 0.75,
                           initialSpringVelocity: 1,
                           options: [.curveEaseOut, .allowAnimatedContent, .allowUserInteraction]) {
                self.overlayContainerView.transform = CGAffineTransform(translationX: 0, y: 0)
            } completion: { completed in
                self.isPerformingDemo = false
            }
        }
    }
    
    func notchHeight(for notch: OverlayNotch, availableSpace: CGFloat) -> CGFloat {
        switch notch {
        case .hidden:
            return 0
        case .minimum:
            return 65
        case .maximum:
            return availableSpace
        }
    }
        
    @objc func didTapFeedNotch() {
        isProgrammaticallyMovingOverlay = true
        switch currentNotch {
        case .hidden:
            break
        case .minimum:
            overlayController.moveOverlay(toNotchAt: OverlayNotch.maximum.rawValue, animated: true)
        case .maximum:
            overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: true)
        }
    }
    
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
        guard
            let notch = OverlayNotch.init(rawValue: index),
            !isFirstLoad
        else { return }
        exploreFeedVC.view.endEditing(true)
        exploreMapVC.view.endEditing(true)
        if currentNotch == .maximum && (notch == .minimum) {
            exploreFeedVC.handleFeedWentDown(duration: 0.3)
            exploreMapVC.handleFeedWentDown(duration: 0.3)
        } else if (currentNotch == .maximum || currentNotch == .minimum) && notch == .maximum {
            exploreFeedVC.handleFeedWentUp(duration: 0.3)
            exploreMapVC.handleFeedWentUp(duration: 0.3)
        }
    }
    
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, didMoveOverlay overlayViewController: UIViewController, toNotchAt index: Int) {
        guard let notch = OverlayNotch.init(rawValue: index) else { return }
        if notch == .maximum {
            DeviceService.shared.didOpenFeed()
            exploreMapVC.dismissPost()
        }
        if notch == .hidden && !isProgrammaticallyMovingOverlay {
            overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: true, completion: nil)
            return
        }
        if notch == .minimum && !DeviceService.shared.getHasUserOpenedFeed() {
            //turning off demo animation for now
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
//                guard self.currentNotch == .minimum && !DeviceService.shared.getHasUserOpenedFeed() else { return }
//                self.performFeedDemoAnimation()
//            }
        }
        if currentNotch == .maximum && notch == .hidden { //don't allow going from max to hidden
            currentNotch = .minimum
            overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: true, completion: nil)
        }
        currentNotch = notch
        isProgrammaticallyMovingOverlay = false
    }
    
    //to fix: slight unideal animation when dragging down and then immediatley letting go on feed overlay
//    var didJustStartDragginDown = false
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, willStartDraggingOverlay overlayViewController: UIViewController) {
        if currentNotch == .maximum {
//            didJustStartDraggingDown = true
            exploreFeedVC.handleFeedWentSlightlyDown(duration: 0.15)
            exploreMapVC.handleFeedWentDown(duration: 0.15)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                self.didJustStartDragginDown = false
//            }
        }
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        scrollViewDrivingOverlay overlayViewController: UIViewController) -> UIScrollView? {
        return nil
//        guard currentNotch == .maximum else { return nil } //don't allow dragging while the notch is down
//        return (overlayViewController as? ExploreFeedViewController)?.feed
    }
    
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        shouldStartDraggingOverlay overlayViewController: UIViewController,
                                        at point: CGPoint,
                                        in coordinateSpace: UICoordinateSpace) -> Bool {
        guard let header = (overlayViewController as? ExploreFeedViewController)?.notchView
        else {
            return false
        }
        let convertedPoint = coordinateSpace.convert(point, to: header)
        return header.bounds.contains(convertedPoint)
    }
    
}
