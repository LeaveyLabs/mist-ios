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
        if !postAnnotations.isEmpty { //this should probably go somewhere else
            feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false) //cant be true
        }
        Task {
            do {
                isLoadingPosts = true
                let (newPosts, newVotes, newFavorites) = try await loadPostsAndUserInteractions()
                UserService.singleton.updateUserInteractionsAfterLoadingPosts(newVotes, newFavorites)
                turnPostsIntoAnnotations(newPosts)
                renderNewPostsOnFeedAndMap(withType: reloadType)
                closure()
            } catch {
                CustomSwiftMessages.displayError(error)
            }
            isLoadingPosts = false
        }
    }
    
    func loadPostsAndUserInteractions() async throws -> ([Post], [Vote], [Favorite]) {
        async let loadedVotes = VoteAPI.fetchVotesByUser(voter: UserService.singleton.getId())
        async let loadedFavorites = FavoriteAPI.fetchFavoritesByUser(userId: UserService.singleton.getId())
        switch self.postFilter.searchBy {
        case .all:
            async let loadedPosts = PostAPI.fetchPosts()
            return try await (loadedPosts, loadedVotes, loadedFavorites)
        case .location:
            let newSearchResultsRegion = getRegionCenteredAround(placeAnnotations)
            async let loadedPosts = PostAPI.fetchPostsByLatitudeLongitude(latitude: newSearchResultsRegion!.center.latitude, longitude: newSearchResultsRegion!.center.longitude, radius: convertLatDeltaToKms(newSearchResultsRegion!.span.latitudeDelta))
            return try await (loadedPosts, loadedVotes, loadedFavorites)
        case .text:
            async let loadedPosts = PostAPI.fetchPostsByWords(words: [searchBarButton.text!])
            return try await (loadedPosts, loadedVotes, loadedFavorites)
        }
    }
    
    func loadCommentThumbnails(for comments: [Comment]) async throws -> [Int: UIImage] {
      var thumbnails: [Int: UIImage] = [:]
      try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
        for comment in comments {
          group.addTask {
              return (comment.id, try await UserAPI.UIImageFromURLString(url: comment.read_only_author.picture))
          }
        }
        for try await (id, thumbnail) in group {
          thumbnails[id] = thumbnail
        }
      }
      return thumbnails
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
    
    func handleVote(postId: Int, isAdding: Bool) {
        // Synchronous viewController update
        let index = postAnnotations.firstIndex { $0.post.id == postId }!
        let originalVoteCount = postAnnotations[index].post.votecount
        postAnnotations[index].post.votecount += isAdding ? 1 : -1
        
        // Synchronous singleton update
        let vote = UserService.singleton.handleVoteUpdate(postId: postId, isAdding)
        
        // Asynchronous remote update
        Task {
            do {
                if isAdding {
                    let _ = try await VoteAPI.postVote(voter: UserService.singleton.getId(), post: postId)
                } else {
                    try await VoteAPI.deleteVote(voter: UserService.singleton.getId(), post: postId)
                }
            } catch {
                UserService.singleton.handleFailedVoteUpdate(with: vote, isAdding) //undo singleton data change
                postAnnotations[index].post.votecount = originalVoteCount //undo viewController data change
                reloadData() //reloadData to ensure undos are visible
                CustomSwiftMessages.displayError(error)
            }
        }
    }
    
    func handleFavorite(postId: Int, isAdding: Bool) {
        // Synchronous singleton update
        let favorite = UserService.singleton.handleFavoriteUpdate(postId: postId, isAdding)

        // Asynchronous remote update
        Task {
            do {
                if isAdding {
                    let _ = try await FavoriteAPI.postFavorite(userId: UserService.singleton.getId(), postId: postId)
                } else {
                    try await FavoriteAPI.deleteFavorite(userId: UserService.singleton.getId(), postId: postId)
                }
            } catch {
                UserService.singleton.handleFailedFavoriteUpdate(with: favorite, isAdding)//undo singleton data change
                reloadData() //reloadData to ensure undos are visible
                CustomSwiftMessages.displayError(error)
            }
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
