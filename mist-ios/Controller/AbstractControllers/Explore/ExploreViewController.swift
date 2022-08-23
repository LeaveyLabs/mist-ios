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
    var keyboardHeight: CGFloat = 0 //emoji keyboard autodismiss flag
    var isKeyboardForEmojiReaction: Bool = false
        
    // Map
    var selectedAnnotationView: MKAnnotationView?
    var selectedAnnotationIndex: Int? {
        guard let selected = selectedAnnotationView else { return nil }
        return postAnnotations.firstIndex(of: selected.annotation as! PostAnnotation)
    }
    
    // Feed
    var reactingPostIndex: Int? //for scrolling to the right index on the feed when react keyboard raises
    
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
    
    //TODO: OOHHH SHIT: maybe it's because i'm reloading the data, and during that reload of data, adjusting the views' positioning
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false) //for a better searchcontroller animation
        reloadData()
        
        //Emoji keyboard autodismiss notification
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillDismiss(sender:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
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
            view.endEditing(true)
        } else {
            makeFeedVisible()
            view.endEditing(true)
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
    
    func handleVote(postId: Int, emoji: String, action: VoteAction) {
        // viewController update
//        let index = postAnnotations.firstIndex { $0.post.id == postId }!
                
        // Singleton & remote update
        do {
            try VoteService.singleton.handleVoteUpdate(postId: postId, emoji: emoji, action)
        } catch {
            reloadData() //reloadData to ensure undos are visible
            CustomSwiftMessages.displayError(error)
        }
    }
    
    func handleBackgroundTap(postId: Int) {
        view.endEditing(true)
        let tappedPostAnnotation = postAnnotations.first { $0.post.id == postId }!
        sendToPostViewFor(tappedPostAnnotation.post, withRaisedKeyboard: false)
    }
    
    func handleCommentButtonTap(postId: Int) {
        view.endEditing(true)
        let tappedPostAnnotation = postAnnotations.first { $0.post.id == postId }!
        sendToPostViewFor(tappedPostAnnotation.post, withRaisedKeyboard: true)
    }
    
    // Helpers
    
    func sendToPostViewFor(_ post: Post, withRaisedKeyboard: Bool) {
        let postVC = PostViewController.createPostVC(with: post, shouldStartWithRaisedKeyboard: withRaisedKeyboard) { updatedPost in
            //TODO: experimental. we dont need to update postannotations anymore
            //Update data to prepare for the next reloadData() upon self.willAppear()
//            let index = postAnnotations.firstIndex { $0.post.id == updatedPost.id }!
//            postAnnotations[index].post = updatedPost
        }
        navigationController!.pushViewController(postVC, animated: true)
    }
    
    func handleDeletePost(postId: Int) {
        renderNewPostsOnFeedAndMap(withType: .refresh)
    }
    
    //MARK: - React interaction
    
    func handleReactTap(postId: Int) {
        //feed's data source is postAnnotations as of now
        reactingPostIndex = postAnnotations.firstIndex { $0.post.id == postId }
        isKeyboardForEmojiReaction = true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        view.endEditing(true)
        guard let postView = textField.superview as? PostView else { return false }
        if !string.isSingleEmoji { return false }
        postView.handleEmojiVote(emojiString: string)
        return false
    }
    
    @objc func keyboardWillChangeFrame(sender: NSNotification) {
        let i = sender.userInfo!
        let previousK = keyboardHeight
        keyboardHeight = (i[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        
        ///don't dismiss the keyboard when toggling to emoji search, which hardly (~1px) lowers the keyboard
        /// and which does lower the keyboard at all (0px) on largest phones
        ///do dismiss it when toggling to normal keyboard, which more significantly (~49px) lowers the keyboard
        if keyboardHeight < previousK - 5 { //keyboard is going from emoji keyboard to regular keyboard
            view.endEditing(true)
        }
        
        if keyboardHeight == previousK && isKeyboardForEmojiReaction {
            //already reacting to one post, tried to react on another post
            isKeyboardForEmojiReaction = false
            if isFeedVisible {
                if let reactingPostIndex = reactingPostIndex {
                    scrollFeedToPostRightAboveKeyboard(reactingPostIndex)
                }
            }
        }
        
        if keyboardHeight > previousK && isKeyboardForEmojiReaction { //keyboard is appearing for the first time && we don't want to scroll the feed when the search controller keyboard is presented
            isKeyboardForEmojiReaction = false
            if isFeedVisible {
                if let reactingPostIndex = reactingPostIndex {
                    scrollFeedToPostRightAboveKeyboard(reactingPostIndex)
                }
            } else {
                if let postAnnotationView = selectedAnnotationView as? PostAnnotationView, keyboardHeight > 100 { //keyboardHeight of 90 appears with postVC keyboard
                    postAnnotationView.movePostUpAfterEmojiKeyboardRaised()
                }
            }
        }
    }
        
    @objc func keyboardWillDismiss(sender: NSNotification) {
        keyboardHeight = 0
        //DONT DO THE FOLLOWING IF THEY"RE CURRENTLY DRAGGING
        if let postAnnotationView = selectedAnnotationView as? PostAnnotationView, !postAnnotationView.isPanning {
            postAnnotationView.movePostBackDownAfterEmojiKeyboardDismissed()
        }
    }

}
