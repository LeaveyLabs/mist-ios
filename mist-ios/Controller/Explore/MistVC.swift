//
//  MistsCollectionView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/10/13.
//

import Foundation
import MapKit
import CenteredCollectionView

class MistCollectionViewController: ExploreMapViewController {
    
    //MARK: - Properties
    
    //UI
    @IBOutlet weak var collectionView: PostCollectionView!
    @IBOutlet weak var customNavBar: CustomNavBar!
    @IBOutlet weak var feedToggleView: FeedToggleView!
    let flowLayout = CenteredCollectionViewFlowLayout()
    
    lazy var newFeedContentOffsetY: CGFloat = BASE_CONTENT_OFFSET
    lazy var BASE_CONTENT_OFFSET = flowLayout.itemSize.height * -0.15 - 14
    var currentPage: Int = 1 {
        didSet {
            feedToggleView.toggleFeed(labelIndex: currentPage)
        }
    }
    
    var visibleFeedCell: FeedCollectionCell? {
        return collectionView.visibleCells.first as? FeedCollectionCell
    }
    var visibleFeed: UITableView? {
        return (collectionView.visibleCells.first as? FeedCollectionCell)?.tableView
    }
    
    //PostDelegate
    var keyboardHeight: CGFloat = 0 //emoji keyboard autodismiss flag
    var isKeyboardForEmojiReaction: Bool = false
    var reactingPostIndex: Int? //for scrolling to the right index on the feed when react keyboard raises
    
    //Flags
    var firstAppearance = true
    var isHandlingNewPost = false
    var isFetchingMorePosts: Bool = false
    var isReadyForNotificationsRequest = false
    var hasRequestedNotifications = false
    
    var isFirstLoad = true
    

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomNavBar(animated: false)
        setupCollectionView()
        setupFeedToggleView()
        setupSearchBar()
        
        self.exploreDelegate = self //mapViewController has an exploreDelegate, too. we'll set ourselves to that (as if we were the parentVC)
        self.postDelegate = self
        
        renderNewPostsOnMap(withType: .firstLoad)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadAllData()
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard isFirstLoad else { return }
        isFirstLoad = false

        flowLayout.scrollToPage(index: 1, animated: false) //viewDidAppear & viewDidLayoutSubviews is too soon
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Setup
    
    func setupCustomNavBar(animated: Bool) {
        customNavBar.configure(title: "mists", leftItems: [.title], rightItems: [.search, .profile], animated: animated)
        customNavBar.accountButton.addTarget(self, action: #selector(handleProfileButtonTap), for: .touchUpInside)
        customNavBar.searchButton.addTarget(self, action: #selector(presentExploreSearchController), for: .touchUpInside)
    }
    
    func setupCollectionView() {
        collectionView.register(FeedCollectionCell.self, forCellWithReuseIdentifier: String(describing: FeedCollectionCell.self))
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "default")

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.isHidden = false //we keep it hidden in storyboard to see easilier
        
        flowLayout.itemSize = view.safeAreaLayoutGuide.layoutFrame.size
//        CGSize(width: view.bounds.width, height: view.bounds.height)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        collectionView.collectionViewLayout = flowLayout
        
        collectionView.contentInset = .init(top: 0, left: 0, bottom: 0, right: 0) //must come after setting the item size
        
        collectionView.isPagingEnabled = true
        collectionView.bounces = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.applyMediumShadow()
    }
    
    func setupFeedToggleView() {
        feedToggleView.configure(labelNames: ["new", "trending", "nearby"], startingSelectedIndex: 1, delegate: self)
    }
    
    //MARK: - Helpers
    
    @MainActor
    func reloadAllData(animated: Bool = false) {
        (tabBarController as? SpecialTabBarController)?.refreshBadgeCount()
        customNavBar.accountBadgeHub.setCount(DeviceService.shared.unreadMentionsCount())

        rerenderCollectionViewForUpdatedPostData()
        let tableViewOne = (collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? FeedCollectionCell)?.tableView
        let tableViewTwo = (collectionView.cellForItem(at: IndexPath(item: 1, section: 0)) as? FeedCollectionCell)?.tableView
        
        if animated {
            tableViewOne?.reloadDataWithViewAnimation(.transitionCrossDissolve, duration: 0.3)
            tableViewTwo?.reloadDataWithViewAnimation(.transitionCrossDissolve, duration: 0.3)
        } else {
            tableViewOne?.reloadData()
            tableViewTwo?.reloadData()
        }
    }
    
}

//MARK: - FeedToggleViewDelegate

extension MistCollectionViewController: FeedToggleViewDelegate {
    
    func labelDidTapped(index: Int) {
        if currentPage == index {
            visibleFeed?.scrollToTop()
        } else {
            flowLayout.scrollToPage(index: index, animated: true)
        }
    }
    
}

//MARK: - UICollectionViewDelegate

extension MistCollectionViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
        recalculatePageControlCurrentPage(scrollView)
        if
            currentPage == 0,
            let newFeed = (collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? FeedCollectionCell)?.tableView {
            newFeedContentOffsetY = newFeed.contentOffset.y
        }
        if currentPage == 2 {
            collectionView.isHidden = false
        }
        guard !mySearchController.isActive else { return }//when starting a search, it triggers the scrollviewdidscroll
        toggleHeaderVisibility(visible: true)
    }
    
    func recalculatePageControlCurrentPage(_ scrollView: UIScrollView) {
        guard let page = flowLayout.currentCenteredPage else { return }
        currentPage = page
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if currentPage == 2 {
            collectionView.isHidden = true
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if currentPage == 2 {
            collectionView.isHidden = true
        }
    }
    
}

//MARK: - UICollectionViewDataSource

//var existingNewPosts: [Post] 
extension MistCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item <= 1 {
            //ACCESS THE CACHE HERE, BELOW
            let posts: [Post]
            if indexPath.item == 0 {
                posts = PostService.singleton.getExploreNewPosts()
            } else {
                posts = PostService.singleton.getExploreBestPosts()
                print("BEST POST COUNT", posts.count)
            }
            let feedCollectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FeedCollectionCell.self), for: indexPath) as! FeedCollectionCell
            feedCollectionCell.configure(postDelegate: self,
                                         exploreDelegate: self,
                                         posts: posts,
                                         position: indexPath.item)
            feedCollectionCell.tableView.reloadData()
            if indexPath.item == 0 {
                feedCollectionCell.tableView.contentOffset.y = newFeedContentOffsetY
            }
            return feedCollectionCell
        } else {
            let defaultCell = collectionView.dequeueReusableCell(withReuseIdentifier: "default", for: indexPath)
            defaultCell.backgroundColor = .clear
            return defaultCell
        }
    }
    
}



//    func waitAndAskForNotifications() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [self] in
//            isReadyForNotificationsRequest = true
//            if SceneDelegate.visibleViewController == self {
//                hasRequestedNotifications = true
//                NotificationsManager.shared.askForNewNotificationPermissionsIfNecessary(permission: .feedNotifications, onVC: self)
//            }
//        }
//    }

//    func setupActiveLabel() {
//        exploreMapVC.trojansActiveView.isHidden = false
//        applyShadowOnView(exploreMapVC.trojansActiveView)
//        exploreMapVC.trojansActiveLabel.text = String(1) + " active"
//        exploreMapVC.trojansActiveView.layer.cornerRadius = 10
//        exploreMapVC.trojansActiveView.layer.cornerCurve = .continuous
//    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        guard isFirstLoad else { return }
//
//
//        guard let firstPostAnnotation = firstPostAnnotation, DeviceService.shared.getStartingScreen() == .map else { return }
//        //set camera first
//        let dynamicLatOffset = (exploreMapVC.latitudeOffsetForOneKMDistance / 1000) * self.exploreMapVC.mapView.camera.centerCoordinateDistance
//        exploreMapVC.mapView.camera.centerCoordinate = CLLocationCoordinate2D(latitude: firstPostAnnotation.coordinate.latitude + dynamicLatOffset, longitude: firstPostAnnotation.coordinate.longitude)
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        if !hasRequestedNotifications && isReadyForNotificationsRequest {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
//                hasRequestedNotifications = true
//                NotificationsManager.shared.askForNewNotificationPermissionsIfNecessary(permission: .feedNotifications, onVC: self)
//            }
//        }
//
//        guard firstAppearance else { return }
//        firstAppearance = false
//
//        guard !isHandlingNewPost else { return }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            UIView.animate(withDuration: 1, delay: 0, options: .curveLinear) {
//                self.exploreMapVC.trojansActiveView.alpha = 0
//            } completion: { completed in
//                self.exploreMapVC.trojansActiveView.isHidden = true
//            }
//        }
//
//        guard let firstPostAnnotation = firstPostAnnotation, DeviceService.shared.getStartingScreen() == .map else { return }
//        //then select post nearest to you
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in//waiting .1 seconds because otherwise the cluster annotation isn't found sometimes
//            let firstAnnotation: MKAnnotation = exploreMapVC.mapView.greatestClusterContaining(firstPostAnnotation) ?? firstPostAnnotation
//            self.exploreMapVC.mapView.selectAnnotation(firstAnnotation, animated: true)
//        }
//    }
