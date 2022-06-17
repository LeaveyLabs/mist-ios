//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

// MARK: - Properties

class ExploreViewController: MapViewController {
    
    // General
    var postFilter = PostFilter()
    var isLoadingPosts: Bool = false {
        didSet {
            //Should also probably disable some other interactions...
            refreshButton.isEnabled = !isLoadingPosts
            refreshButton.configuration?.showsActivityIndicator = isLoadingPosts
        }
    }
    @IBOutlet weak var customNavigationBar: UIView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var toggleButton: UIButton!
    
    // Feed
    var tableView: UITableView!
    var tableViewNeedsScrollToTop = false
                
    // Search
    @IBOutlet weak var searchBarButton: UISearchBar!
    var mySearchController: UISearchController!
    var searchSuggestionsVC: SearchSuggestionsTableViewController!
    var boundingRegion: MKCoordinateRegion = MKCoordinateRegion(MKMapRect.world)
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
        navigationController?.setNavigationBarHidden(true, animated: false) //for a better searchcontroller animation
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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
    }
}

//MARK: - Getting posts

extension ExploreViewController {
    
    func setupRefreshButton() {
        applyShadowOnView(refreshButton)
        refreshButton.layer.cornerCurve = .continuous
        refreshButton.layer.cornerRadius = 10
        refreshButton.addTarget(self, action: #selector(reloadPosts as () -> ()), for: .touchUpInside)
    }
    
    func renderInitialPosts() {
        renderPostsAsAnnotations(PostsService.initialPosts)
    }
    
    @objc func reloadPosts() {
        isLoadingPosts = true
        Task {
            do {
                let loadedPosts = try await PostsService.newPosts()
                renderPostsAsAnnotations(loadedPosts)
                tableView.refreshControl?.endRefreshing()
            } catch {
                CustomSwiftMessages.showError(errorDescription: error.localizedDescription)
            }
            isLoadingPosts = false
            tableViewNeedsScrollToTop = true
        }
    }
    
    func reloadPosts(afterReload: @escaping () -> Void?) {
        isLoadingPosts = true
        Task {
            do {
                let loadedPosts = try await PostsService.newPosts()
                renderPostsAsAnnotations(loadedPosts)
                tableView.refreshControl?.endRefreshing()
                afterReload()
            } catch {
                CustomSwiftMessages.showError(errorDescription: error.localizedDescription)
            }
            isLoadingPosts = false
            tableViewNeedsScrollToTop = true
        }
    }
    
    func renderPostsAsAnnotations(_ posts: [Post]) {
        guard posts.count > 0 else { return }
        let maxPostsToRender = 10000
        postAnnotations = []
        for index in 0...min(maxPostsToRender, posts.count-1) {
            let postAnnotation = PostAnnotation(withPost: posts[index])
            postAnnotations.append(postAnnotation)
        }
        postAnnotations.sort()
    }
    
}

// MARK: - Toggle

extension ExploreViewController {
    
    func setupCustomNavigationBar() {
        customNavigationBar.applyMediumShadowBelowOnly()
    }
    
    @IBAction func toggleButtonDidTapped(_ sender: UIButton) {
        tableView.isHidden = !tableView.isHidden
        if tableView.isHidden {
            toggleButton.setImage(UIImage(named: "toggle-list-button"), for: .normal)
        } else {
            toggleButton.setImage(UIImage(named: "toggle-map-button"), for: .normal)
            if tableViewNeedsScrollToTop {
                //setting the scrollStartRow and then delaying the reloadData by 0.1 seconds should prevent issues where the new data is less than the previous data and the user scroll far down so uitableviewcells aren't rendered properly. Yet the scroll to top animation is still provided
                let scrollStartRow = min(tableView.indexPathsForVisibleRows![0].row, 10)
                tableView.scrollToRow(at: IndexPath(row: scrollStartRow, section: 0), at: .top, animated: false)
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.tableView.reloadData()
                }
                tableViewNeedsScrollToTop = false
            }
        }
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
}

extension ExploreViewController: FilterDelegate {
    
    func handleUpdatedFilter(_ newPostFilter: PostFilter, shouldReload: Bool, _ afterFilterUpdate: @escaping () -> Void) {
    
        postFilter = newPostFilter
//        updateFilterButtonLabel() //incase we want to handle UI updates somehow
        if shouldReload {
            reloadPosts(afterReload: afterFilterUpdate)
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
            self.reloadPosts()
        }
        navigationController!.pushViewController(postVC, animated: true)
    }

}
