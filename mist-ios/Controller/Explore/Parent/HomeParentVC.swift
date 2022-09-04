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
    var isHandlingNewPost = true
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshableFeed()
        setupActiveLabel()
//        tabBarController?.selectedIndex = 1
    }
    
    func setupActiveLabel() {
        exploreMapVC.trojansActiveView.isHidden = false
        applyShadowOnView(exploreMapVC.trojansActiveView)
        exploreMapVC.trojansActiveLabel.text = String(1) + " active"
        exploreMapVC.trojansActiveView.layer.cornerRadius = 10
        exploreMapVC.trojansActiveView.layer.cornerCurve = .continuous
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard firstAppearance else { return }
        firstAppearance = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            self.renderNewPostsOnFeedAndMap(withType: .firstLoad)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard !hasRequestedLocationPermissionsDuringAppSession else { return }
                self.exploreMapVC.requestUserLocationPermissionIfNecessary()
                hasRequestedLocationPermissionsDuringAppSession = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            UIView.animate(withDuration: 1, delay: 0, options: .curveLinear) {
                self.exploreMapVC.trojansActiveView.alpha = 0
            } completion: { completed in
                self.exploreMapVC.trojansActiveView.isHidden = true
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isHandlingNewPost {
            isHandlingNewPost = false
            overlayController.moveOverlay(toNotchAt: OverlayNotch.minimum.rawValue, animated: false)
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
    
    func handleNewlySubmittedPost() {
        exploreMapVC.annotationSelectionType = .submission
        renderNewPostsOnFeedAndMap(withType: .newPost)
        guard let newPostAnnotation = exploreMapVC.postAnnotations.first else { return }
        
        //Feed
        exploreFeedVC.feed.reloadData() //need to reload data after rearranging posts
        exploreFeedVC.feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        
        //Map
        exploreMapVC.slowFlyWithoutZoomTo(lat: newPostAnnotation.coordinate.latitude, long: newPostAnnotation.coordinate.longitude, withDuration: exploreMapVC.cameraAnimationDuration + 2) { completed in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in //adding a delay because otherwise we get "annotation is not added to map" sometimes??
                let greatestCluster = greatestClusterContaining(newPostAnnotation)
                exploreMapVC.mapView.selectAnnotation(greatestCluster ?? newPostAnnotation, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    NotificationsManager.shared.askForNewNotificationPermissionsIfNecessary(permission: .dmNotificationsAfterNewPost, onVC: self)
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


// MARK: - Filter

extension HomeExploreParentViewController: FilterDelegate {
            
    //User Interaction
    
    @IBAction func filterButtonDidTapped(_ sender: UIButton) {
        exploreMapVC.dismissPost()
        let filterVC = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Filter) as! FilterSheetViewController
        filterVC.selectedFilter = PostService.singleton.getExploreFilter() //TODO: just use the singleton directly, don't need to pass it intermediately
        filterVC.delegate = self
        filterVC.loadViewIfNeeded() //doesnt work without this function call
        present(filterVC, animated: true)
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
