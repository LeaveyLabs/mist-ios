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
    case refresh, cancel, newSearch, newPost, firstLoad
}

class ExploreViewController: MapViewController {
    
    // UI
    @IBOutlet weak var customNavigationBar: UIView!
    @IBOutlet weak var toggleButton: UIButton!
    var feed: UITableView!
    
    //Flags
    var reloadTask: Task<Void, Never>?
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        latitudeOffset = 0.00095
        setupCustomNavigationBar()
        setupCustomTapGestureRecognizerOnMap()
        
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
    }
    
}

//MARK: - Getting / refreshing posts

extension ExploreViewController {
    
    func renderNewPostsOnFeedAndMap(withType reloadType: ReloadType, customSetting: Setting? = nil) {
        //Feed scroll to top, on every reload. this should happen BEFORE the datasource for the feed is altered, in order to prevent a potential improper element access
        if reloadType != .firstLoad {
            if !postAnnotations.isEmpty {
                feed.isUserInteractionEnabled = false
                feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                feed.isUserInteractionEnabled = true
            }
        }
        //Map camera travel, only on new searches
        
        removeExistingPlaceAnnotationsFromMap()
        removeExistingPostAnnotationsFromMap()
        //Both data update
        if let setting = customSetting {
            if setting == .submissions {
                turnPostsIntoAnnotations(PostService.singleton.getSubmissions())
            } else if setting == .favorites {
                turnPostsIntoAnnotations(PostService.singleton.getFavorites())
            }
        } else {
            turnPostsIntoAnnotations(PostService.singleton.getExplorePosts())
        }
        //if at some point we decide to list out places in the feed results, too, then turnPlacesIntoAnnoations should be moved here
        //the reason we don't need to rn is because the feed is not dependent on place data, just post data, and we should scroll to top of feed before refreshing the data

        if reloadType == .newSearch {
            mapView.region = getRegionCenteredAround(postAnnotations + placeAnnotations) ?? PostService.singleton.getExploreFilter().region
        }

        //Feed visual update
        feed.reloadData()
        //Map visual update
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
        let postVC = PostViewController.createPostVC(with: post, shouldStartWithRaisedKeyboard: withRaisedKeyboard) { [self] updatedPost in
            //Update data to prepare for the next reloadData() upon self.willAppear()
            let index = postAnnotations.firstIndex { $0.post.id == updatedPost.id }!
            postAnnotations[index].post = updatedPost
        }
        navigationController!.pushViewController(postVC, animated: true)
    }
    
    func handleDeletePost(postId: Int) {
        renderNewPostsOnFeedAndMap(withType: .refresh)
    }
    
}
