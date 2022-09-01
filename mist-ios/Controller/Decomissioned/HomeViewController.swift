////
////  HomeViewController.swift
////  mist-ios
////
////  Created by Adam Monterey on 7/12/22.
////
//
//import Foundation
//import MapKit
//
//class HomeViewController: ExploreMapViewController {
//
//    //MARK: - Properties
//
//    @IBOutlet weak var refreshButton: UIButton!
//    var isLoadingPosts: Bool = false {
//        didSet {
//            //Should also probably disable some other interactions...
//            refreshButton.isEnabled = !isLoadingPosts
//            refreshButton.configuration?.showsActivityIndicator = isLoadingPosts
//            if !isLoadingPosts {
//                feed.refreshControl?.endRefreshing()
//            }
//        }
//    }
//
//    var hasViewAppearedOnce = false
//
//    //MARK: - Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupRefreshButton()
//        setupRefreshableFeed()
//        tabBarController?.selectedIndex = 1
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        // Handle controller being exposed from push/present or pop/dismiss
//        if (self.isMovingToParent || self.isBeingPresented){
//            // Controller is being pushed on or presented.
//        }
//        else {
//            // Controller is being shown as result of pop/dismiss/unwind.
//            mySearchController.searchBar.becomeFirstResponder()
//        }
//        if !hasViewAppearedOnce {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                self.renderNewPostsOnFeedAndMap(withType: .firstLoad)
//            }
//        }
//        hasViewAppearedOnce = true
//        // Dependent on map dimensions
////        searchBarButton.centerText()
//    }
//
//    //MARK: - Setup
//
//    override func setupCustomNavigationBar() {
//        navigationController?.isNavigationBarHidden = true
//        view.addSubview(customNavBar)
//        customNavBar.configure(title: "explore", leftItems: [.title], rightItems: [.search], delegate: self)
//    }
//
//}
//
////MARK: - NavBarDelegate
//
//extension HomeViewController: CustomNavBarDelegate {
//
//    func handleFilterButtonTap() {
//        //do nothing for now
//    }
//
//    func handleMapFeedToggleButtonTap() {
////        toggleButtonDidTapped()
//    }
//
//    func handleSearchButtonTap() {
//        presentExploreSearchController()
//    }
//
//}
//
//
//
////MARK: - Getting posts
//
//extension HomeViewController {
//
//    func setupRefreshableFeed() {
//        feed.refreshControl = UIRefreshControl()
//        feed.refreshControl!.addAction(.init(handler: { [self] _ in
//            reloadPosts(withType: .refresh)
//        }), for: .valueChanged)
//    }
//
//    func setupRefreshButton() {
//        applyShadowOnView(refreshButton)
//        refreshButton.layer.cornerCurve = .continuous
//        refreshButton.layer.cornerRadius = 10
//        refreshButton.addAction(.init(handler: { [self] _ in
//            reloadPosts(withType: .refresh)
//        }), for: .touchUpInside)
//    }
//
//    //TODO: if there's a reload task in progress, cancel it, and wait for the most recent one
//    func reloadPosts(withType reloadType: ReloadType, closure: @escaping () -> Void = { } ) {
//        Task {
//            do {
//                isLoadingPosts = true
//                try await loadPostStuff() //takes into account the updated post filter in PostsService
//                isLoadingPosts = false
//
//                DispatchQueue.main.async { [self] in
//                    renderNewPostsOnFeedAndMap(withType: reloadType)
//                    closure()
//                }
//            } catch {
//                if !Task.isCancelled {
//                    CustomSwiftMessages.displayError(error)
//                    isLoadingPosts = false
//                }
//            }
//        }
//    }
//
//    // To make the map fly directly to the middle of cluster locations...
//    // After loading the annotations for the map, immediately center the camera around the annotation
//    // (as if it had flown there), check if it's an annotation, then set the camera back to USC
//    func handleNewlySubmittedPost() {
//        annotationSelectionType = .submission
//        renderNewPostsOnFeedAndMap(withType: .newPost)
//        if let newPostAnnotation = postAnnotations.first {
//            feed.reloadData() //need to reload data after rearranging posts
//            feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
////            slowFlyOutAndIn(lat: newPostAnnotation.coordinate.latitude + latitudeOffset,
////                            long: newPostAnnotation.coordinate.longitude,
////                            withDuration: cameraAnimationDuration+2) { finished in
////                self.mapView.selectAnnotation(newPostAnnotation, animated: true)
////            }
//            slowFlyTo(lat: newPostAnnotation.coordinate.latitude + latitudeOffset,
//                      long: newPostAnnotation.coordinate.longitude,
//                      incrementalZoom: false,
//                      withDuration: cameraAnimationDuration+2,
//                      completion: { [self] _ in
//                mapView.selectAnnotation(newPostAnnotation, animated: true)
//            })
//        }
//    }
//
//}
//
//
//// MARK: - Filter
//
//extension HomeViewController {
//
//    //User Interaction
//
//    @IBAction func filterButtonDidTapped(_ sender: UIButton) {
//        dismissPost()
//        let filterVC = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Filter) as! FilterSheetViewController
//        filterVC.selectedFilter = PostService.singleton.getExploreFilter() //TODO: just use the singleton directly, don't need to pass it intermediately
//        filterVC.delegate = self
//        filterVC.loadViewIfNeeded() //doesnt work without this function call
//        present(filterVC, animated: true)
//    }
//
//    // Helpers
//
//    func resetCurrentFilter() {
////        searchBarButton.text = ""
////        searchBarButton.centerText()
////        searchBarButton.searchTextField.leftView?.tintColor = .secondaryLabel
////        searchBarButton.setImage(UIImage(systemName: "magnifyingglass"), for: .search, state: .normal)
//        placeAnnotations = []
//        removeExistingPlaceAnnotationsFromMap()
//        PostService.singleton.resetFilter()
//        reloadPosts(withType: .cancel)
//    }
//
//}
//
//extension HomeViewController: FilterDelegate {
//
//    func handleUpdatedFilter(_ newPostFilter: PostFilter, shouldReload: Bool, _ afterFilterUpdate: @escaping () -> Void) {
//        PostService.singleton.updateFilter(newPostFilter: newPostFilter)
////        updateFilterButtonLabel() //incase we want to handle UI updates somehow
//        if shouldReload {
//            reloadPosts(withType: .newSearch, closure: afterFilterUpdate)
//        }
//    }
//
//}
