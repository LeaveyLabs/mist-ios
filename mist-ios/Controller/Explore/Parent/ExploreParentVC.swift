//
//  NewExploreViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/30/22.
//

import Foundation
import OverlayContainer
import UIKit

protocol ExploreChildDelegate {
    func renderNewPostsOnFeedAndMap(withType reloadType: ReloadType, customSetting: Setting?)
    func reloadData()
    
    var posts: [Post] { get }
}

enum OverlayNotch: Int, CaseIterable {
    case minimum, maximum
}

class ExploreParentViewController: UIViewController {

    //MARK: - Properties
    
    //Overlay
    @IBOutlet var overlayContainerView: UIView!
    @IBOutlet var backgroundView: UIView!
    var exploreMapVC: ExploreMapViewController!
    var exploreFeedVC: ExploreFeedViewController!
    var overlayController = OverlayContainerViewController()
    var currentNotch: OverlayNotch = .minimum
    
    //PostDelegate
    var loadAuthorProfilePicTasks: [Int: Task<FrontendReadOnlyUser?, Never>] = [:]
    var keyboardHeight: CGFloat = 0 //emoji keyboard autodismiss flag
    var isKeyboardForEmojiReaction: Bool = false
    var reactingPostIndex: Int? //for scrolling to the right index on the feed when react keyboard raises

    //ExploreChildDelegate
    var posts = PostService.singleton.getExplorePosts()
//    var currentFilter: PostFilter!
    
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
}

// MARK: - OverlayContainer

extension ExploreParentViewController: OverlayContainerViewControllerDelegate {
    
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
    
    private func notchHeight(for notch: OverlayNotch, availableSpace: CGFloat) -> CGFloat {
        switch notch {
        case .maximum:
            return availableSpace
        case .minimum:
            return 65
        }
    }
        
    @objc func didTapFeedNotch() {
        switch currentNotch {
        case .minimum:
            overlayController.moveOverlay(toNotchAt: OverlayNotch.maximum.rawValue, animated: true, completion: nil)
        case .maximum:
            overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: true, completion: nil)
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
        } else if (currentNotch == .minimum) && notch == .maximum {
            exploreFeedVC.handleFeedWentUp(duration: 0.3)
            exploreMapVC.handleFeedWentUp(duration: 0.3)
        }
    }
    
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, didMoveOverlay overlayViewController: UIViewController, toNotchAt index: Int) {
        guard let notch = OverlayNotch.init(rawValue: index) else { return }
        currentNotch = notch
        if notch == .maximum {
            exploreMapVC.dismissPost()
        }
        print(currentNotch)
    }
    
    //to fix: slight unideal animation when dragging down and then immediatley letting go on feed overlay
//    var didJustStartDragginDown = false
    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, willStartDraggingOverlay overlayViewController: UIViewController) {
        if currentNotch == .maximum {
//            didJustStartDraggingDown = true
            exploreFeedVC.handleFeedWentDown(duration: 0.15)
            exploreMapVC.handleFeedWentDown(duration: 0.15)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                self.didJustStartDragginDown = false
//            }
        }
    }

    func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        scrollViewDrivingOverlay overlayViewController: UIViewController) -> UIScrollView? {
//        guard currentNotch == .maximum else { return nil } //don't allow dragging while the notch is down
        return (overlayViewController as? ExploreFeedViewController)?.feed
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
