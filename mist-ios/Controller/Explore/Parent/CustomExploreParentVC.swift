//
//  CustomExploreParentVC.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/31/22.
//

import Foundation
import OverlayContainer

class CustomExploreParentViewController: ExploreParentViewController {
    
    enum OverlayNotch: Int, CaseIterable {
        case hidden, minimum, medium, maximum
    }
    
    //MARK: - Properties
    
    var setting: Setting!
    var feedBottomConstraint: NSLayoutConstraint!
    var currentCustomNotch: OverlayNotch = .minimum
    
    override var mapPosts: [Post] {
        switch setting {
        case .submissions:
            return PostService.singleton.getSubmissions()
        case .mentions:
            return PostService.singleton.getMentions()
        case .favorites:
            return PostService.singleton.getFavorites()
        default:
            return []
        }
    }
    override var feedPosts: [Post] {
        switch setting {
        case .submissions:
            return PostService.singleton.getSubmissions()
        case .mentions:
            return PostService.singleton.getMentions()
        case .favorites:
            return PostService.singleton.getFavorites()
        default:
            return []
        }
    }
    
    //MARK: - Initialization
    
    class func create(setting: Setting) -> CustomExploreParentViewController? {
        guard setting == .favorites || setting == .submissions || setting == .mentions else { return nil }
        let vc = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.CustomExploreParent) as! CustomExploreParentViewController
        vc.setting = setting
        return vc
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitleLabel()
        setupBackButton()
        navigationController?.fullscreenInteractivePopGestureRecognizer(delegate: self)
        renderNewPostsOnFeed(withType: .newSearch)
        renderNewPostsOnMap(withType: .newSearch) //using newSearch in order to force a relocation of the map
        if setting == .mentions {
            DeviceService.shared.didViewMentions()
        }
        overlayController.moveOverlay(toNotchAt: OverlayNotch.medium.rawValue, animated: false, completion: nil)
        exploreFeedVC.refreshButton.isHidden = false
        exploreFeedVC.filterButton.isHidden = true
    }
    
    //MARK: - Override Overlay
    
    func notchHeight(for notch: OverlayNotch, availableSpace: CGFloat) -> CGFloat {
        switch notch {
        case .hidden:
            return 65
        case .minimum:
            return 65
        case .medium:
            return 300
        case .maximum:
            return availableSpace
        }
    }
        
    @objc override func didTapFeedNotch() {
        switch currentCustomNotch {
        case .hidden:
            break
        case .minimum, .medium:
            overlayController.moveOverlay(toNotchAt: OverlayNotch.maximum.rawValue, animated: true, completion: nil)
        case .maximum:
            overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: true, completion: nil)
        }
    }
    
    override func numberOfNotches(in containerViewController: OverlayContainerViewController) -> Int {
        return OverlayNotch.allCases.count
    }

    override func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        heightForNotchAt index: Int,
                                        availableSpace: CGFloat) -> CGFloat {
        let notch = OverlayNotch.allCases[index]
        return notchHeight(for: notch, availableSpace: availableSpace)
    }
    
    override func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, willMoveOverlay overlayViewController: UIViewController, toNotchAt index: Int) {
        guard
            let notch = OverlayNotch.init(rawValue: index),
            !isFirstLoad
        else { return }
        exploreFeedVC.view.endEditing(true)
        exploreMapVC.view.endEditing(true)
        if currentCustomNotch == .maximum && (notch == .minimum) {
            exploreFeedVC.handleFeedWentDown(duration: 0.3)
            exploreMapVC.handleFeedWentDown(duration: 0.3)
        } else if (currentCustomNotch == .maximum || currentCustomNotch == .minimum) && notch == .maximum {
            exploreFeedVC.handleFeedWentUp(duration: 0.3)
            exploreMapVC.handleFeedWentUp(duration: 0.3)
        }
    }
    
    override func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, didMoveOverlay overlayViewController: UIViewController, toNotchAt index: Int) {
        guard let notch = OverlayNotch.init(rawValue: index) else { return }
        if notch == .maximum {
            exploreMapVC.dismissPost()
        }
        if currentCustomNotch == .maximum && notch == .hidden { //don't allow going from max to hidden
            currentCustomNotch = .minimum
            overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: true, completion: nil)
        }
        currentCustomNotch = notch
    }
    
    //to fix: slight unideal animation when dragging down and then immediatley letting go on feed overlay
//    var didJustStartDragginDown = false
    override func overlayContainerViewController(_ containerViewController: OverlayContainerViewController, willStartDraggingOverlay overlayViewController: UIViewController) {
        if currentCustomNotch == .maximum {
//            didJustStartDraggingDown = true
            exploreFeedVC.handleFeedWentDown(duration: 0.15)
            exploreMapVC.handleFeedWentDown(duration: 0.15)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                self.didJustStartDragginDown = false
//            }
        }
    }

    override func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
                                        scrollViewDrivingOverlay overlayViewController: UIViewController) -> UIScrollView? {
//        guard currentCustomNotch == .maximum else { return nil } //don't allow dragging while the notch is down
        return (overlayViewController as? ExploreFeedViewController)?.feed
    }
    
    override func overlayContainerViewController(_ containerViewController: OverlayContainerViewController,
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
    
    
    //MARK: - Helpers
    
    func setupTitleLabel() {
        let titleLabel = exploreFeedVC.navStackView.arrangedSubviews.first(where: { $0 .isKind(of: UILabel.self )}) as? UILabel
        titleLabel?.text = setting.displayName
    }
    
    func setupBackButton() {
        let backButton = UIButton()
        let backImage = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default))!
        backButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        backButton.addTarget(self, action: #selector(backButtonDidTapped(_:)), for: .touchUpInside)
        backButton.setImage(backImage, for: .normal)
        exploreFeedVC.navStackView.insertArrangedSubview(backButton, at: 0)
    }
    
    //MARK: - User Interaction

    @objc func backButtonDidTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    //MARK: - ExploreDelegate
    
    override func reloadNewMapPostsIfNecessary() {
        //do nothing in custom parent
    }
    
    override func reloadNewFeedPostsIfNecessary() {
        //do nothing
    }
    
    
}


