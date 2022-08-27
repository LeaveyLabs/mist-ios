//
//  HomeViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/12/22.
//

import Foundation
import MapKit

class HomeViewController: ExploreViewController {
    
    //MARK: - Properties

    @IBOutlet weak var refreshButton: UIButton!
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
    
    //MARK: - Lifecycle

    override func loadView() {
        super.loadView()
        setupSearchBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshButton()
        renderNewPostsOnFeedAndMap(withType: .firstLoad)
        setupRefreshableFeed()
        setupCustomNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
    
    //MARK: - Setup
    
    override func setupCustomNavigationBar() {
        navigationController?.isNavigationBarHidden = true
        view.addSubview(customNavBar)
        customNavBar.configure(title: "explore", leftItems: [.title], rightItems: [.filter, .map], delegate: self)
    }
    
}

extension HomeViewController: CustomNavBarDelegate {
    
    func handleFilterButtonTap() {
        //do nothing for now
    }
    
    func handleFeedButtonTap() {
        toggleButtonDidTapped()
    }
    
    func handleMapButtonTap() {
        toggleButtonDidTapped()
    }
    
    func handleSearchButtonTap() {
        presentExploreSearchController()
    }
    
}



//MARK: - Getting posts

extension HomeViewController {
    
    func setupRefreshableFeed() {
        feed.refreshControl = UIRefreshControl()
        feed.refreshControl!.addAction(.init(handler: { [self] _ in
            reloadPosts(withType: .refresh)
        }), for: .valueChanged)
    }
    
    func setupRefreshButton() {
        applyShadowOnView(refreshButton)
        refreshButton.layer.cornerCurve = .continuous
        refreshButton.layer.cornerRadius = 10
        refreshButton.addAction(.init(handler: { [self] _ in
            reloadPosts(withType: .refresh)
        }), for: .touchUpInside)
    }
    
    //TODO: if there's a reload task in progress, cancel it, and wait for the most recent one
    func reloadPosts(withType reloadType: ReloadType, closure: @escaping () -> Void = { } ) {
        if isLoadingPosts { reloadTask?.cancel() }
        reloadTask = Task {
            do {
                isLoadingPosts = true
                try await loadPostStuff() //takes into account the updated post filter in PostsService
                isLoadingPosts = false
                
                DispatchQueue.main.async { [self] in
                    renderNewPostsOnFeedAndMap(withType: reloadType)
                    closure()
                }
            } catch {
                if !Task.isCancelled {
                    CustomSwiftMessages.displayError(error)
                    isLoadingPosts = false
                }
            }
        }
    }
    
}


// MARK: - Filter

extension HomeViewController {
            
    //User Interaction
    
    @IBAction func filterButtonDidTapped(_ sender: UIButton) {
        dismissPost()
        let filterVC = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Filter) as! FilterSheetViewController
        filterVC.selectedFilter = PostService.singleton.getExploreFilter() //TODO: just use the singleton directly, don't need to pass it intermediately
        filterVC.delegate = self
        filterVC.loadViewIfNeeded() //doesnt work without this function call
        present(filterVC, animated: true)
    }
    
    // Helpers
    
    func resetCurrentFilter() {
//        searchBarButton.text = ""
//        searchBarButton.centerText()
//        searchBarButton.searchTextField.leftView?.tintColor = .secondaryLabel
//        searchBarButton.setImage(UIImage(systemName: "magnifyingglass"), for: .search, state: .normal)
        placeAnnotations = []
        removeExistingPlaceAnnotationsFromMap()
        PostService.singleton.resetFilter()
        reloadPosts(withType: .cancel)
    }
    
}

extension HomeViewController: FilterDelegate {
    
    func handleUpdatedFilter(_ newPostFilter: PostFilter, shouldReload: Bool, _ afterFilterUpdate: @escaping () -> Void) {
        PostService.singleton.updateFilter(newPostFilter: newPostFilter)
//        updateFilterButtonLabel() //incase we want to handle UI updates somehow
        if shouldReload {
            reloadPosts(withType: .newSearch, closure: afterFilterUpdate)
        }
    }
        
}
