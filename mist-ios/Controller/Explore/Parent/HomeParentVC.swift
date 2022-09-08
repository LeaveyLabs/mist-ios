//
//  HomeParentVC.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/31/22.
//

import Foundation
import MapKit

class HomeExploreParentViewController: ExploreParentViewController {
    
    //MARK: - Properties
    
    var firstAppearance = true
    var isHandlingNewPost = false
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshableFeed()
        setupActiveLabel()
        setupTabBar()
    }
    
    func setupTabBar() {
        guard let tabBarVC = tabBarController as? SpecialTabBarController else { return }
        tabBarVC.selectedIndex = 1
    }
    
    func setupActiveLabel() {
        exploreMapVC.trojansActiveView.isHidden = false
        applyShadowOnView(exploreMapVC.trojansActiveView)
        exploreMapVC.trojansActiveLabel.text = String(1) + " active"
        exploreMapVC.trojansActiveView.layer.cornerRadius = 10
        exploreMapVC.trojansActiveView.layer.cornerCurve = .continuous
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isHandlingNewPost {
            isHandlingNewPost = false
            overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard firstAppearance else { return }
        firstAppearance = false
        guard !isHandlingNewPost else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            self.renderNewPostsOnFeedAndMap(withType: .firstLoad)
            if !hasRequestedLocationPermissionsDuringAppSession && (CLLocationManager.authorizationStatus() == .denied ||
                CLLocationManager.authorizationStatus() == .notDetermined) {
                hasRequestedLocationPermissionsDuringAppSession = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.exploreMapVC.requestUserLocationPermissionIfNecessary()
                }
                
            } else {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
//                    if let cluster = exploreMapVC.mapView?.greatestClusterAnnotation {
//                        exploreMapVC.mapView.
//                        exploreMapVC.mapView.selectAnnotation(cluster, animated: true)
//                    } else if let annotation = exploreMapVC.postAnnotations.first {
//                        exploreMapVC.mapView.selectAnnotation(annotation, animated: true)
//                    }
//                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            UIView.animate(withDuration: 1, delay: 0, options: .curveLinear) {
                self.exploreMapVC.trojansActiveView.alpha = 0
            } completion: { completed in
                self.exploreMapVC.trojansActiveView.isHidden = true
            }
        }
        
    }
    
}


//MARK: - Getting posts

extension HomeExploreParentViewController {
    
    func setupRefreshableFeed() {
//        feed.refreshControl = UIRefreshControl()
//        feed.refreshControl!.addAction(.init(handler: { [self] _ in
//            reloadPosts(withType: .refresh)
//        }), for: .valueChanged)
    }
    
    func reloadPosts(withType reloadType: ReloadType, closure: @escaping () -> Void = { } ) {
        Task {
            do {
//                isLoadingPosts = true
                try await loadPostStuff() //takes into account the updated post filter in PostsService
//                isLoadingPosts = false
                
                DispatchQueue.main.async { [self] in
                    renderNewPostsOnFeedAndMap(withType: reloadType)
                    closure()
                }
            } catch {
                if !Task.isCancelled {
                    CustomSwiftMessages.displayError(error)
//                    isLoadingPosts = false
                }
            }
        }
    }
    
    @MainActor
    func handleNewlySubmittedPost() {
        exploreMapVC.annotationSelectionType = .submission
        renderNewPostsOnFeedAndMap(withType: .newPost)
        guard let newPostAnnotation = exploreMapVC.postAnnotations.first else { return }
        
        //Feed
        exploreFeedVC.feed.reloadData() //need to reload data after rearranging posts
        exploreFeedVC.feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        
        //Map
        exploreMapVC.slowFlyWithoutZoomTo(lat: newPostAnnotation.coordinate.latitude, long: newPostAnnotation.coordinate.longitude, withDuration: exploreMapVC.cameraAnimationDuration + 2, withLatitudeOffset: true) { [self] completed in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in //delay prevents cluster annotations from getting immediatley deselected
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationsManager.shared.askForNewNotificationPermissionsIfNecessary(permission: .dmNotificationsAfterNewPost, onVC: self)
                }
                if let greatestCluster = greatestClusterContaining(newPostAnnotation) {
                    exploreMapVC.mapView.selectAnnotation(greatestCluster, animated: true)
                } else {
                    if let rerenderedAnnotation = exploreMapVC.mapView.annotations.first(where: {
                        ($0 as? PostAnnotation)?.post.id == newPostAnnotation.post.id
                    }) {
                        exploreMapVC.mapView.selectAnnotation(rerenderedAnnotation, animated: true)
                    }
                }
            }
            
        }
    }
    
    func greatestClusterContaining(_ postAnnotation: PostAnnotation) -> MKClusterAnnotation? {
        var candidateClusters = [MKClusterAnnotation]()
        for annotation in exploreMapVC.mapView.annotations {
            guard let cluster = annotation as? MKClusterAnnotation,
                  cluster.memberAnnotations.contains(where: {
                      ($0 as? PostAnnotation)?.post == postAnnotation.post })
            else {
                continue
            }
            candidateClusters.append(cluster)
        }
        return candidateClusters.sorted(by: { $0.memberAnnotations.count > $1.memberAnnotations.count }).first
    }
    
}

extension MKMapView {
    
    var greatestClusterAnnotation: MKClusterAnnotation? {
        var greatestClusterAnnotation: MKClusterAnnotation? = nil
        annotations.forEach { annotation in
            if let cluster = annotation as? MKClusterAnnotation, cluster.memberAnnotations.count > greatestClusterAnnotation?.memberAnnotations.count ?? 0 {
                greatestClusterAnnotation = cluster
            }
        }
        return greatestClusterAnnotation
    }
    
}


// MARK: - Filter

extension HomeExploreParentViewController: FilterDelegate {
            
    //User Interaction
    
    @IBAction func filterButtonDidTapped(_ sender: UIButton) {
//        exploreMapVC.dismissPost()
//        let filterVC = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Filter) as! FilterSheetViewController
//        filterVC.selectedFilter = PostService.singleton.getExploreFilter() //TODO: just use the singleton directly, don't need to pass it intermediately
//        filterVC.delegate = self
//        filterVC.loadViewIfNeeded() //doesnt work without this function call
//        present(filterVC, animated: true)
    }
    
    // Helpers
    
    func resetCurrentFilter() {
//        placeAnnotations = []
//        removeExistingPlaceAnnotationsFromMap()
//        PostService.singleton.resetFilter()
//        reloadPosts(withType: .cancel)
    }
    
    func handleUpdatedFilter(_ newPostFilter: PostFilter, shouldReload: Bool, _ afterFilterUpdate: @escaping () -> Void) {
        PostService.singleton.updateFilter(newPostFilter: newPostFilter)
//        updateFilterButtonLabel() //incase we want to handle UI updates somehow
        if shouldReload {
            reloadPosts(withType: .newSearch, closure: afterFilterUpdate)
        }
    }
    
}

//MARK: - Deprecated

//        setupRefreshButton()
//    func setupRefreshButton() {
//        applyShadowOnView(refreshButton)
//        refreshButton.layer.cornerCurve = .continuous
//        refreshButton.layer.cornerRadius = 10
//        refreshButton.addAction(.init(handler: { [self] _ in
//            reloadPosts(withType: .refresh)
//        }), for: .touchUpInside)
//    }

//var isLoadingPosts: Bool = false {
//    didSet {
//        //Should also probably disable some other interactions...
//        refreshButton.isEnabled = !isLoadingPosts
//        refreshButton.configuration?.showsActivityIndicator = isLoadingPosts
//        if !isLoadingPosts {
//            feed.refreshControl?.endRefreshing()
//        }
//    }
//}
