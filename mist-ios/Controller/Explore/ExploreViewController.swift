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
    
    //experimental, for debugging purposes only
    var appleregion: MKCoordinateRegion = .init()
    
    // UI
    @IBOutlet weak var customNavigationBar: UIView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var searchBarButton: UISearchBar!
    @IBOutlet weak var refreshButton: UIButton!
    var feed: UITableView!
    var mySearchController: UISearchController!
    var searchSuggestionsVC: SearchSuggestionsTableViewController!
    
    //Flags
    var reloadTask: Task<Void, Never>?
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
    var isFeedVisible = false //we have to use this flag and send tableview to the front/back instead of using isHidden so that when tableviewcells aren't rerendered when tableview reappears and so we can have a scroll to top animation before reloading tableview data
    var annotationSelectionType: AnnotationSelectionType = .normal
        
    // Map
    var selectedAnnotationView: MKAnnotationView?
    var selectedAnnotationIndex: Int? {
        guard let selected = selectedAnnotationView else { return nil }
        return postAnnotations.firstIndex(of: selected.annotation as! PostAnnotation)
    }
    
    //PostDelegate
    var loadAuthorProfilePicTasks: [Int: Task<FrontendReadOnlyUser?, Never>] = [:]
}

// MARK: - View Life Cycle

extension ExploreViewController {

    override func loadView() {
        super.loadView()
        setupTableView()
        setupSearchBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        latitudeOffset = 0.00095
        
        makeFeedVisible()
        
        setupSearchBarButton()
        setupRefreshButton()
        setupCustomTapGestureRecognizerOnMap()
        renderInitialPosts()
        setupCustomNavigationBar()
        
        if let userLocation = locationManager.location {
            mapView.camera.centerCoordinate = userLocation.coordinate
            mapView.camera.centerCoordinateDistance = 3000
            mapView.camera.pitch = 40
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false) //for a better searchcontroller animation
        reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false) //for a better searchcontroller animation
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
//        searchBarButton.centerText()
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
        turnPostsIntoAnnotations(PostService.singleton.getPosts())
        mapView.addAnnotations(postAnnotations)
    }
    
    //TODO: if there's a reload task in progress, cancel it, and wait for the most recent one
    func reloadPosts(withType reloadType: ReloadType, closure: @escaping () -> Void = { } ) {
        if !postAnnotations.isEmpty { //this should probably go somewhere else
            feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false) //cant be true
        }
        if isLoadingPosts { reloadTask!.cancel() }
        reloadTask = Task {
            do {
                isLoadingPosts = true
                try await loadEverything() //takes into account the updated post filter in PostsService
                isLoadingPosts = false
                turnPostsIntoAnnotations(PostService.singleton.getPosts())
                renderNewPostsOnFeedAndMap(withType: reloadType)
                closure()
            } catch {
                if !Task.isCancelled {
                    CustomSwiftMessages.displayError(error)
                    isLoadingPosts = false
                }
            }
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
            mapView.region = appleregion
            mapView.region = getRegionCenteredAround(postAnnotations + placeAnnotations) ?? PostService.singleton.getFilter().region
        }
        //then, in one moment, remove all existing annotations and add all new ones
        removeExistingPlaceAnnotationsFromMap()
        removeExistingPostAnnotationsFromMap()
        mapView.addAnnotations(placeAnnotations)
        mapView.addAnnotations(postAnnotations)
    }
    
}

// MARK: - Toggle

extension ExploreViewController {
    
    func setupCustomNavigationBar() {
        customNavigationBar.applyMediumBottomOnlyShadow()
    }
    
    @IBAction func toggleButtonDidTapped(_ sender: UIButton) {
        reloadData()
        if isFeedVisible {
            makeMapVisible()
        } else {
            makeFeedVisible()
        }
    }
    
    // Called upon every viewWillAppear and map/feed toggle
    func reloadData() {
        //Map
        if let selectedPostAnnotationView = selectedAnnotationView as? PostAnnotationView {
            selectedPostAnnotationView.rerenderCalloutForUpdatedPostData()
        }
        //Feed
        DispatchQueue.main.async { // somehow, this prevents a strange animation for the reload
            self.feed.reloadData()
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
        filterVC.selectedFilter = PostService.singleton.getFilter() //TODO: just use the singleton directly, don't need to pass it intermediately
        filterVC.delegate = self
        filterVC.loadViewIfNeeded() //doesnt work without this function call
        present(filterVC, animated: true)
    }
    
    // Helper
    
    func resetCurrentFilter() {
        searchBarButton.text = ""
//        searchBarButton.centerText()
        searchBarButton.searchTextField.leftView?.tintColor = .secondaryLabel
        searchBarButton.setImage(UIImage(systemName: "magnifyingglass"), for: .search, state: .normal)
        placeAnnotations = []
        removeExistingPlaceAnnotationsFromMap()
        PostService.singleton.resetFilter()
        reloadPosts(withType: .cancel)
    }
    
}

extension ExploreViewController: FilterDelegate {
    
    func handleUpdatedFilter(_ newPostFilter: PostFilter, shouldReload: Bool, _ afterFilterUpdate: @escaping () -> Void) {
        PostService.singleton.updateFilter(newPostFilter: newPostFilter)
//        updateFilterButtonLabel() //incase we want to handle UI updates somehow
        if shouldReload {
            reloadPosts(withType: .newSearch, closure: afterFilterUpdate)
        }
    }
        
}

//MARK: - Post Delegation

extension ExploreViewController: PostDelegate {
    
    func handleVote(postId: Int, isAdding: Bool) {
        // viewController update
        let index = postAnnotations.firstIndex { $0.post.id == postId }!
        let originalVoteCount = postAnnotations[index].post.votecount
        postAnnotations[index].post.votecount += isAdding ? 1 : -1
        
        // Singleton & remote update
        do {
            try VoteService.singleton.handleVoteUpdate(postId: postId, isAdding)
        } catch {
            postAnnotations[index].post.votecount = originalVoteCount //undo viewController data change
            reloadData() //reloadData to ensure undos are visible
            CustomSwiftMessages.displayError(error)
        }
    }
    
    func handleBackgroundTap(postId: Int) {
        let tappedPostAnnotation = postAnnotations.first { $0.post.id == postId }!
        sendToPostViewFor(tappedPostAnnotation.post, withRaisedKeyboard: false)
    }
    
    func handleCommentButtonTap(postId: Int) {
        let tappedPostAnnotation = postAnnotations.first { $0.post.id == postId }!
        sendToPostViewFor(tappedPostAnnotation.post, withRaisedKeyboard: true)
    }
    
    // Helpers
    
    func sendToPostViewFor(_ post: Post, withRaisedKeyboard: Bool) {
        let postVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
        postVC.post = post
        postVC.shouldStartWithRaisedKeyboard = withRaisedKeyboard
        postVC.prepareForDismiss = { [self] updatedPost in
            //Update data to prepare for the next reloadData() upon self.willAppear()
            let index = postAnnotations.firstIndex { $0.post.id == updatedPost.id }!
            postAnnotations[index].post = updatedPost
        }
        navigationController!.pushViewController(postVC, animated: true)
    }
    
}
