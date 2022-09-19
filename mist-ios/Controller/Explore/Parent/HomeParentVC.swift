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
    var isFetchingMorePosts: Bool = false
    lazy var firstPostAnnotation: PostAnnotation = {
//        if let userCenter = exploreMapVC.locationManager.location {
//            return exploreMapVC.postAnnotations.sorted(by: { $0.coordinate.distanceInKilometers(from: userCenter.coordinate) < $1.coordinate.distanceInKilometers(from: userCenter.coordinate) } ).first!
//        } else {
            return exploreMapVC.postAnnotations.randomElement()!
//        }
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActiveLabel()
        setupTabBar()
        renderNewPostsOnFeed(withType: .firstLoad)
        renderNewPostsOnMap(withType: .firstLoad)
    }
    
    func setupTabBar() {
//        guard let tabBarVC = tabBarController as? SpecialTabBarController else { return }
//        if MistboxManager.shared.getMistboxMists().count > 0 || DeviceService.shared.unreadMentionsCount() > 0 {
//            tabBarVC.selectedIndex = 1
//        }
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
        
        guard isFirstLoad else { return }
        
        //set camera first
        let dynamicLatOffset = (exploreMapVC.latitudeOffsetForOneKMDistance / 1000) * self.exploreMapVC.mapView.camera.centerCoordinateDistance
        exploreMapVC.mapView.camera.centerCoordinate = CLLocationCoordinate2D(latitude: firstPostAnnotation.coordinate.latitude + dynamicLatOffset, longitude: firstPostAnnotation.coordinate.longitude)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard firstAppearance else { return }
        firstAppearance = false
        
        guard !isHandlingNewPost else { return }
        
        //then select post nearest to you
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in//waiting .1 seconds because otherwise the cluster annotation isn't found sometimes
            let firstAnnotation: MKAnnotation = exploreMapVC.mapView.greatestClusterContaining(firstPostAnnotation) ?? firstPostAnnotation
            self.exploreMapVC.mapView.selectAnnotation(firstAnnotation, animated: true)
        }
        
        if !DeviceService.shared.hasBeenRequestedLocationOnHome() && (CLLocationManager.authorizationStatus() == .denied ||
            CLLocationManager.authorizationStatus() == .notDetermined) {
            DeviceService.shared.showHomeLocationRequest()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.exploreMapVC.requestUserLocationPermissionIfNecessary()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 1, delay: 0, options: .curveLinear) {
                self.exploreMapVC.trojansActiveView.alpha = 0
            } completion: { completed in
                self.exploreMapVC.trojansActiveView.isHidden = true
            }
        }
    }
    
    override func reloadNewMapPostsIfNecessary() {
        guard !isFetchingMorePosts && PostService.singleton.isReadyForNewMapSearch() else { return }
        isFetchingMorePosts = true
        Task {
            do {
                try await PostService.singleton.loadAndAppendExploreMapPosts()
                DispatchQueue.main.async { [self] in
                    renderNewPostsOnMap(withType: .addMore)
                    isFetchingMorePosts = false
                }
            } catch {
                print("ERROR LOADING IN MAP POSTS IN BACKGROUND WHILE SCROLLING")
                isFetchingMorePosts = false
            }
        }
    }
    
    override func reloadNewFeedPostsIfNecessary() {
        guard !isFetchingMorePosts else { return }
        isFetchingMorePosts = true
        Task {
            do {
                try await PostService.singleton.loadExploreFeedPostsIfPossible()
                DispatchQueue.main.async { [self] in
                    renderNewPostsOnFeed(withType: .addMore)
                    isFetchingMorePosts = false
                }
            } catch {
                isFetchingMorePosts = false
                print("ERROR LOADING IN MAP POSTS IN BACKGROUND WHILE SCROLLING")
            }
        }
    }
    
}


//MARK: - Getting posts

extension HomeExploreParentViewController {
    
    @MainActor
    func handleNewlySubmittedPost(didJustShowNotificaitonsRequest: Bool) {
        exploreMapVC.annotationSelectionType = .submission
        renderNewPostsOnFeed(withType: .newPost)
        renderNewPostsOnMap(withType: .newPost)
        guard let newPostAnnotation = exploreMapVC.postAnnotations.first else { return }
        
        //Feed
        exploreFeedVC.feed.reloadData() //need to reload data after rearranging posts
        exploreFeedVC.feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        
        //Map
        exploreMapVC.slowFlyWithoutZoomTo(lat: newPostAnnotation.coordinate.latitude, long: newPostAnnotation.coordinate.longitude, withDuration: exploreMapVC.cameraAnimationDuration + 2, withLatitudeOffset: true) { [self] completed in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in //delay prevents cluster annotations from getting immediatley deselected
                if !didJustShowNotificaitonsRequest {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        AppStoreReviewManager.requestReviewIfAppropriate()
                    }
                }
                
                if let greatestCluster = exploreMapVC.mapView.greatestClusterContaining(newPostAnnotation) {
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
    
}


// MARK: - Filter

extension HomeExploreParentViewController: FilterDelegate {
    
    @MainActor
    func handleUpdatedExploreFilter() {
        //We should scroll to top before we alter the dataSource for the feed or else we risk scrolling through rows which were full but are nowed empty
        if !feedPosts.isEmpty {
            exploreFeedVC.feed.isUserInteractionEnabled = false
            exploreFeedVC.feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            exploreFeedVC.feed.isUserInteractionEnabled = true
        }
        Task {
            try await PostService.singleton.loadExploreFeedPostsIfPossible() //page count is set to 0 when resetting sorting
            DispatchQueue.main.async {
                self.renderNewPostsOnFeed(withType: .firstLoad)
            }
        }
    }
    
}
