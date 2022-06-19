//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

// MARK: - Properties

enum ReloadType {
    case refresh, cancel, newSearch, newPost
}

class ExploreViewController: MapViewController {
    
    // General
    var postFilter = PostFilter()
    var isLoadingPosts: Bool = false {
        didSet {
            //Should also probably disable some other interactions...
            refreshButton.isEnabled = !isLoadingPosts
            refreshButton.configuration?.showsActivityIndicator = isLoadingPosts
            if !isLoadingPosts {
                feed.refreshControl?.endRefreshing()
            }
        }
    }
    @IBOutlet weak var customNavigationBar: UIView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var toggleButton: UIButton!
    
    // Feed
    var feed: UITableView!
    var isFeedVisible = false //we have to use this flag and send tableview to the front/back instead of using isHidden so that when tableviewcells aren't rerendered when tableview reappears and so we can have a scroll to top animation before reloading tableview data
                
    // Search
    @IBOutlet weak var searchBarButton: UISearchBar!
    var mySearchController: UISearchController!
    var searchSuggestionsVC: SearchSuggestionsTableViewController!
    var localSearch: MKLocalSearch? {
        willSet {
            // Clear the results and cancel the currently running local search before starting a new search.
            localSearch?.cancel()
        }
    }
    
    // Map
    @IBOutlet weak var refreshButton: UIButton!
    var selectedAnnotationView: MKAnnotationView?
    var selectedAnnotationIndex: Int? {
        guard let selected = selectedAnnotationView else { return nil }
        return postAnnotations.firstIndex(of: selected.annotation as! PostAnnotation)
    }
    enum AnnotationSelectionType { // Flag for didSelect(annotation)
        case submission, swipe, normal
    }
    var annotationSelectionType: AnnotationSelectionType = .normal
    
}

// MARK: - View Life Cycle

extension ExploreViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        latitudeOffset = 0.00095
        
        setupSearchBarButton()
        setupRefreshButton()
        setupSearchBar()
        setupTableView()
        setupCustomTapGestureRecognizerOnMap()
        renderInitialPosts()
        setupCustomNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        searchBarButton.centerText()
        navigationController?.setNavigationBarHidden(true, animated: false) //for a better searchcontroller animation
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false) //for a better searchcontroller animation
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let userLocation = locationManager.location {
            mapView.camera.centerCoordinate = userLocation.coordinate
            mapView.camera.centerCoordinateDistance = 3000
            mapView.camera.pitch = 40
        }
        enableInteractivePopGesture()
        // Handle controller being exposed from push/present or pop/dismiss
        if (self.isMovingToParent || self.isBeingPresented){
            // Controller is being pushed on or presented.
        }
        else {
            // Controller is being shown as result of pop/dismiss/unwind.
            mySearchController.searchBar.becomeFirstResponder()
        }
        
        // Dependent on map dimensions
        searchBarButton.centerText()
    }
    
}

//MARK: - Getting posts

extension ExploreViewController {
    
    func setupRefreshButton() {
        applyShadowOnView(refreshButton)
        refreshButton.layer.cornerCurve = .continuous
        refreshButton.layer.cornerRadius = 10
        refreshButton.addAction(.init(handler: { [self] _ in
            reloadPosts(withType: .refresh)
        }), for: .touchUpInside)
    }
    
    func renderInitialPosts() {
        turnPostsIntoAnnotations(PostsService.initialPosts)
        mapView.addAnnotations(postAnnotations)
    }
    
    func reloadPosts(withType reloadType: ReloadType, closure: @escaping () -> Void = { } ) {
        isLoadingPosts = true
        if !postAnnotations.isEmpty { //this should probably go somewhere else
            feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        Task {
            do {
                let loadedPosts: [Post]!
                switch postFilter.searchBy {
                case .all:
                    loadedPosts = try await PostAPI.fetchPosts()
                case .location:
                    let newSearchResultsRegion = getRegionCenteredAround(placeAnnotations)
                    loadedPosts = try await PostAPI.fetchPostsByLatitudeLongitude(latitude: newSearchResultsRegion!.center.latitude, longitude: newSearchResultsRegion!.center.longitude, radius: convertLatDeltaToKms(newSearchResultsRegion!.span.latitudeDelta))
                case .text:
                    loadedPosts = try await PostAPI.fetchPostsByText(text: searchBarButton.text!)
                }
                turnPostsIntoAnnotations(loadedPosts)
                renderNewPostsOnFeedAndMap(withType: reloadType)
                closure()
            } catch {
                CustomSwiftMessages.displayError(error)
            }
            isLoadingPosts = false
        }
    }
    
    //At this point, we have new posts to render.
    //Scroll view should scroll to top with existing data, then reload data
    //Map view should fly to new location, then de-render old annotations, then render new annotations
    func renderNewPostsOnFeedAndMap(withType reloadType: ReloadType) {
        //TABLE VIEW
        self.feed.reloadData()
        
        //MAP VIEW
        if reloadType == .newSearch {
            mapView.region = getRegionCenteredAround(postAnnotations + placeAnnotations) ?? mapView.region
        }
        //then, in one moment, remove all existing annotations and add all new ones
        removeExistingPlaceAnnotations()
        removeExistingPostAnnotations()
        mapView.addAnnotations(placeAnnotations)
        mapView.addAnnotations(postAnnotations)
    }
    
}

// MARK: - Toggle

extension ExploreViewController {
    
    func setupCustomNavigationBar() {
        customNavigationBar.applyMediumShadowBelowOnly()
    }
    
    @IBAction func toggleButtonDidTapped(_ sender: UIButton) {
        if isFeedVisible {
            makeMapVisible()
        } else {
            makeFeedVisible()
        }
    }
    
    func makeFeedVisible() {
        view.insertSubview(feed, belowSubview: customNavigationBar)
        toggleButton.setImage(UIImage(named: "toggle-map-button"), for: .normal)
        isFeedVisible = true
    }
    
    func makeMapVisible() {
        view.sendSubviewToBack(feed)
        toggleButton.setImage(UIImage(named: "toggle-list-button"), for: .normal)
        isFeedVisible = false
    }
    
}

// MARK: - Filter

extension ExploreViewController {
            
    //User Interaction
    
    @IBAction func filterButtonDidTapped(_ sender: UIButton) {
        dismissPost()
        let filterVC = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Filter) as! FilterSheetViewController
        filterVC.selectedFilter = postFilter
        filterVC.delegate = self
        filterVC.loadViewIfNeeded() //doesnt work without this function call
        present(filterVC, animated: true)
    }
    
    // Helper
    
    func resetCurrentFilteredSearch() {
        searchBarButton.text = ""
        searchBarButton.centerText()
        searchBarButton.searchTextField.leftView?.tintColor = .secondaryLabel
        searchBarButton.setImage(UIImage(systemName: "magnifyingglass"), for: .search, state: .normal)
        postFilter = .init()
        reloadPosts(withType: .cancel)
    }
    
}

extension ExploreViewController: FilterDelegate {
    
    func handleUpdatedFilter(_ newPostFilter: PostFilter, shouldReload: Bool, _ afterFilterUpdate: @escaping () -> Void) {
        postFilter = newPostFilter
//        updateFilterButtonLabel() //incase we want to handle UI updates somehow
        if shouldReload {
            reloadPosts(withType: .newSearch, closure: afterFilterUpdate)
        }
    }
        
}

//MARK: - Post Delegation

extension ExploreViewController: PostDelegate {
    
    func backgroundDidTapped(post: Post) {
        sendToPostViewFor(post, withRaisedKeyboard: false)
    }
    
    func commentDidTapped(post: Post) {
        sendToPostViewFor(post, withRaisedKeyboard: true)
    }
    
    // Helpers
    
    func sendToPostViewFor(_ post: Post, withRaisedKeyboard: Bool) {
        let postVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
        postVC.post = post
        postVC.shouldStartWithRaisedKeyboard = withRaisedKeyboard
        postVC.completionHandler = { Post in
//            reloadPosts(withType: .refresh)
            //TODO: uhh.. how to make sure the post is updated? i have to update the postannotation's post
        }
        navigationController!.pushViewController(postVC, animated: true)
    }

}
