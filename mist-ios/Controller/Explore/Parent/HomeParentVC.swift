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
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshableFeed()
        setupActiveLabel()
        tabBarController?.selectedIndex = 1
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.renderNewPostsOnFeedAndMap(withType: .firstLoad)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard !hasRequestedLocationPermissionsDuringAppSession else { return }
                self.exploreMapVC.requestUserLocationPermissionIfNecessary()
                hasRequestedLocationPermissionsDuringAppSession = true
            }
        }
        
        UIView.animate(withDuration: 1, delay: 7, options: .curveLinear) {
            self.exploreMapVC.trojansActiveView.alpha = 0
        } completion: { completed in
            self.exploreMapVC.trojansActiveView.isHidden = true
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
        exploreMapVC.slowFlyTo(lat: newPostAnnotation.coordinate.latitude + exploreMapVC.latitudeOffset,
                  long: newPostAnnotation.coordinate.longitude,
                  incrementalZoom: false,
                               withDuration: exploreMapVC.cameraAnimationDuration+2,
                  completion: { [self] _ in
            let newPostClusteredAnnotation = exploreMapVC.mapView.annotations.first(where: { annotation in
                guard let cluster = annotation as? MKClusterAnnotation,
                      cluster.memberAnnotations.contains(where: { $0.title == newPostAnnotation.title })
                else { return false }
                return true
            })
            exploreMapVC.mapView.selectAnnotation(newPostClusteredAnnotation ?? newPostAnnotation, animated: true)
        })
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
