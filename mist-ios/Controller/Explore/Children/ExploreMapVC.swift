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

class ExploreMapViewController: MapViewController {
    
    // UI
    let whiteStatusBar = UIImageView(image: UIImage.imageFromColor(color: .white))
    
    // Delegate
    var postDelegate: PostDelegate!
    var exploreDelegate: ExploreChildDelegate!
    
    //Flags
    var annotationSelectionType: AnnotationSelectionType = .normal
        
    // Map
    var selectedAnnotationView: AnnotationViewWithPosts? {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in //because we might immediately deselect and select
                let shouldZoomBeHidden = selectedAnnotationView != nil
//                zoomStackView.isHidden = false
                exploreButtonStackView.isHidden = false
                trackingDimensionStackView.isHidden = false
                UIView.animate(withDuration: 0.2) {
//                    self.zoomStackView.alpha = shouldZoomBeHidden ? 0 : 1
                    self.exploreButtonStackView.alpha = shouldZoomBeHidden ? 0 : 1
                    self.trackingDimensionStackView.alpha = shouldZoomBeHidden ? 0 : 1
                    self.zoomSliderGradientImageView.alpha = shouldZoomBeHidden ? 0 : 0.3
                    if shouldZoomBeHidden {
                        self.trojansActiveView.alpha = 0
                    }
                } completion: { completed in
//                    self.zoomStackView.isHidden = shouldZoomBeHidden
                    self.exploreButtonStackView.isHidden = shouldZoomBeHidden
                    self.trackingDimensionStackView.isHidden = shouldZoomBeHidden
                    if shouldZoomBeHidden {
                        self.trojansActiveView.isHidden = true
                    }
                }
            }

        }
    }
    
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var exploreButtonStackView: UIStackView!
    @IBOutlet weak var trojansActiveView: UIView!
    @IBOutlet weak var trojansActiveLabel: UILabel!
    
    // Search
    var mySearchController: UISearchController!
    var searchSuggestionsVC: SearchSuggestionsTableViewController!
    //experimental, for debugging purposes only
    var appleregion: MKCoordinateRegion = .init()
}

// MARK: - Life Cycle

extension ExploreMapViewController {
    
    class func create(postDelegate: PostDelegate, exploreDelegate: ExploreChildDelegate) -> ExploreMapViewController {
        let exploreMapVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ExploreMap) as! ExploreMapViewController
        exploreMapVC.postDelegate = postDelegate
        exploreMapVC.exploreDelegate = exploreDelegate
        return exploreMapVC
    }

    override func loadView() {
        super.loadView()
        setupSearchBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        setupCustomTapGestureRecognizerOnMap()
        setupWhiteStatusBar()
        setupBlurredStatusBar()
        setupExploreMapButtons()
        setupTrojansActiveView()

        if let userLocation = locationManager.location {
            mapView.camera.centerCoordinate = userLocation.coordinate
            mapView.camera.centerCoordinateDistance = MapViewController.STARTING_ZOOM_DISTANCE
            mapView.camera.pitch = maxCameraPitch
        }
    }
    
    func setupTrojansActiveView() {
        trojansActiveView.isHidden = true //default. it's only unhidden for the home version
        Task {
            let usersCount = await UsersService.singleton.getTotalUsersCount() ?? 50
            let hourOfDay = Calendar.current.component(.hour, from: Date())
            let hourlyDecrement = abs(hourOfDay - 12) * 7
            let dayOfWeek = Calendar.current.component(.weekday, from: Date())
            let dailyIncrement = abs(dayOfWeek-4) * 19
            let varied = usersCount * 4 - hourlyDecrement + dailyIncrement
            await MainActor.run {
                trojansActiveLabel.text = formattedVoteCount(Double(varied)) + " active"
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false) //for a better searchcontroller animation
//        reloadData()
//
//        //Emoji keyboard autodismiss notification
//        NotificationCenter.default.addObserver(self,
//            selector: #selector(keyboardWillChangeFrame),
//            name: UIResponder.keyboardWillShowNotification,
//            object: nil)
//
//        NotificationCenter.default.addObserver(self,
//            selector: #selector(keyboardWillDismiss(sender:)),
//            name: UIResponder.keyboardWillHideNotification,
//            object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        NotificationCenter.default.removeObserver(self)
        navigationController?.setNavigationBarHidden(false, animated: false) //for a better searchcontroller animation
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        enableInteractivePopGesture()
        moveMapLegalLabel()
        
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

//MARK: - Getting / refreshing posts

extension ExploreMapViewController {
    
//    func renderNewPostsOnFeedAndMap(withType reloadType: ReloadType, customSetting: Setting? = nil) {
//        //Feed scroll to top, on every reload. this should happen BEFORE the datasource for the feed is altered, in order to prevent a potential improper element access
//        if reloadType != .firstLoad {
//            if !postAnnotations.isEmpty {
//                feed.isUserInteractionEnabled = false
//                feed.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
//                feed.isUserInteractionEnabled = true
//            }
//        }
//        //Map camera travel, only on new searches
//
//        removeExistingPlaceAnnotationsFromMap()
//        removeExistingPostAnnotationsFromMap()
//        //Both data update
//        if let setting = customSetting {
//            if setting == .submissions {
//                turnPostsIntoAnnotations(PostService.singleton.getSubmissions())
//            } else if setting == .favorites {
//                turnPostsIntoAnnotations(PostService.singleton.getFavorites())
//            } else if setting == .mentions {
//                turnPostsIntoAnnotations(PostService.singleton.getMentions())
//            } else if setting == .mistbox {
//                turnPostsIntoAnnotations(PostService.singleton.getMistboxPosts())
//            }
//        } else {
//            turnPostsIntoAnnotations(PostService.singleton.getExplorePosts())
//        }
//        //if at some point we decide to list out places in the feed results, too, then turnPlacesIntoAnnoations should be moved here
//        //the reason we don't need to rn is because the feed is not dependent on place data, just post data, and we should scroll to top of feed before refreshing the data
//
//        if reloadType == .newSearch {
//            mapView.region = getRegionCenteredAround(postAnnotations + placeAnnotations) ?? PostService.singleton.getExploreFilter().region
//        }
//
//        //Feed visual update
//        feed.reloadData()
//        //Map visual update
//        mapView.addAnnotations(placeAnnotations)
//        mapView.addAnnotations(postAnnotations)
//    }
    
}

// MARK: - Toggle

extension ExploreMapViewController {
    
//    func toggleButtonDidTapped() {
//        reloadData()
//        if isFeedVisible {
//            makeMapVisible()
//            view.endEditing(true)
//        } else {
//            makeFeedVisible()
//            view.endEditing(true)
//        }
//    }
//
//    // Called upon every viewWillAppear and map/feed toggle
//    func reloadData() {
//        DispatchQueue.main.async {
//            self.selectedAnnotationView?.rerenderCalloutForUpdatedPostData()
//            self.feed.reloadData()
//        }
//    }
        
//    func makeFeedVisible() {
//        feed.alpha = 0
//        view.insertSubview(feed, belowSubview: customNavBar)
//        view.isUserInteractionEnabled = false
//        UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear) {
//            self.feed.alpha = 1
//        } completion: { [self] completed in
//            isFeedVisible = true
//            view.isUserInteractionEnabled = true
//        }
//    }
//
//    func makeMapVisible() {
//        feed.alpha = 1
//        view.isUserInteractionEnabled = false
//        UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear) {
//            self.feed.alpha = 0
//        } completion: { [self] completed in
//            view.sendSubviewToBack(feed)
//            isFeedVisible = false
//            view.isUserInteractionEnabled = true
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                guard !hasRequestedLocationPermissionsDuringAppSession else { return }
//                self.requestUserLocationPermissionIfNecessary()
//                hasRequestedLocationPermissionsDuringAppSession = true
//            }
//
//        }
//    }
    
}
//
////MARK: - Post Delegation
//
//extension ExploreViewController: PostDelegate {
//    
//    func handleVote(postId: Int, emoji: String, action: VoteAction) {
//        // viewController update
////        let index = postAnnotations.firstIndex { $0.post.id == postId }!
//                
//        // Singleton & remote update
//        do {
//            try VoteService.singleton.handlePostVoteUpdate(postId: postId, emoji: emoji, action)
//        } catch {
//            reloadData() //reloadData to ensure undos are visible
//            CustomSwiftMessages.displayError(error)
//        }
//    }
//    
//    func handleBackgroundTap(postId: Int) {
//        view.endEditing(true)
//        let tappedPostAnnotation = postAnnotations.first { $0.post.id == postId }!
//        sendToPostViewFor(tappedPostAnnotation.post, withRaisedKeyboard: false)
//    }
//    
//    func handleCommentButtonTap(postId: Int) {
//        view.endEditing(true)
//        let tappedPostAnnotation = postAnnotations.first { $0.post.id == postId }!
//        sendToPostViewFor(tappedPostAnnotation.post, withRaisedKeyboard: true)
//    }
//    
//    // Helpers
//    
//    func sendToPostViewFor(_ post: Post, withRaisedKeyboard: Bool) {
//        let postVC = PostViewController.createPostVC(with: post, shouldStartWithRaisedKeyboard: withRaisedKeyboard) { updatedPost in
//            //TODO: experimental. we dont need to update postannotations anymore
//            //Update data to prepare for the next reloadData() upon self.willAppear()
////            let index = postAnnotations.firstIndex { $0.post.id == updatedPost.id }!
////            postAnnotations[index].post = updatedPost
//        }
//            navigationController!.pushViewController(postVC, animated: true)
//    }
//    
//    func handleDeletePost(postId: Int) {
//        renderNewPostsOnFeedAndMap(withType: .refresh)
//    }
//    
//    //MARK: - React interaction
//    
//    func handleReactTap(postId: Int) {
//        //feed's data source is postAnnotations as of now
//        reactingPostIndex = postAnnotations.firstIndex { $0.post.id == postId }
//        isKeyboardForEmojiReaction = true
//    }
//    
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        view.endEditing(true)
//        guard let postView = textField.superview as? PostView else { return false }
//        if !string.isSingleEmoji { return false }
//        postView.handleEmojiVote(emojiString: string)
//        return false
//    }
//    
//    @objc func keyboardWillChangeFrame(sender: NSNotification) {
//        let i = sender.userInfo!
//        let previousK = keyboardHeight
//        keyboardHeight = (i[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
//        
//        ///don't dismiss the keyboard when toggling to emoji search, which hardly (~1px) lowers the keyboard
//        /// and which does lower the keyboard at all (0px) on largest phones
//        ///do dismiss it when toggling to normal keyboard, which more significantly (~49px) lowers the keyboard
//        if keyboardHeight < previousK - 5 { //keyboard is going from emoji keyboard to regular keyboard
//            view.endEditing(true)
//        }
//        
//        if keyboardHeight == previousK && isKeyboardForEmojiReaction {
//            //already reacting to one post, tried to react on another post
//            isKeyboardForEmojiReaction = false
//            if isFeedVisible {
//                if let reactingPostIndex = reactingPostIndex {
//                    scrollFeedToPostRightAboveKeyboard(reactingPostIndex)
//                }
//            }
//        }
//        
//        if keyboardHeight > previousK && isKeyboardForEmojiReaction { //keyboard is appearing for the first time && we don't want to scroll the feed when the search controller keyboard is presented
//            isKeyboardForEmojiReaction = false
//            if isFeedVisible {
//                if let reactingPostIndex = reactingPostIndex {
//                    scrollFeedToPostRightAboveKeyboard(reactingPostIndex)
//                }
//            } else {
//                if let postAnnotationView = selectedAnnotationView, keyboardHeight > 100 { //keyboardHeight of 90 appears with postVC keyboard
//                    postAnnotationView.movePostUpAfterEmojiKeyboardRaised()
//                }
//            }
//        }
//    }
//        
//    @objc func keyboardWillDismiss(sender: NSNotification) {
//        keyboardHeight = 0
//        //DONT DO THE FOLLOWING IF THEY"RE CURRENTLY DRAGGING
//        if let postAnnotationView = selectedAnnotationView { //!postAnnotationView.isPanning { this was useful when we allowed swiping between postsAnnotationViews. not needed anymore
//            postAnnotationView.movePostBackDownAfterEmojiKeyboardDismissed()
//        }
//    }
//
//}
