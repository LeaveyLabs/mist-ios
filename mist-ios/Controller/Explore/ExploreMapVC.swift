//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit
import CenteredCollectionView

// MARK: - Properties

enum ReloadType {
    case firstLoad, addMore, newSearch, newPost
}

struct LocationTapContext {
    var lat, long: Double
    var postId: Int
}

class ExploreMapViewController: MapViewController {
    
    static var locationTapContext: LocationTapContext? = nil
    
    // UI
    let whiteStatusBar = UIImageView(image: UIImage.imageFromColor(color: .white))
        
    // Delegate
    var postDelegate: PostDelegate!
    var exploreDelegate: ExploreChildDelegate!
    var keyboardHeight: CGFloat = 0 //emoji keyboard autodismiss flag
    var isKeyboardForEmojiReaction: Bool = false
    var reactingPostIndex: Int? //for scrolling to the right index on the feed when react keyboard raises
    
    var isFirstLoad = true
        
    //Flags
    var annotationSelectionType: AnnotationSelectionType = .normal
    var isFirstAppearance = true
    var isFetchingMorePosts = false

    lazy var MAP_VIEW_WIDTH: Double = Double(mapView?.bounds.width ?? 350)
    lazy var POST_VIEW_WIDTH: Double = MAP_VIEW_WIDTH * 0.5 + 100
    lazy var POST_VIEW_MARGIN: Double = (MAP_VIEW_WIDTH - POST_VIEW_WIDTH) / 2
    lazy var POST_VIEW_MAX_HEIGHT: Double = (((mapView?.frame.height ?? 500) * 0.75) - 110.0)
    
    var selectedAnnotationView: AnnotationViewWithPosts? {
        willSet {
            selectedAnnotationView?.derenderCallout() //we can't reliably derender the callout within the clusterAnnotationView, because sometimes it'll just poof away without removinng it itself
        }
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in //because we might immediately deselect and select
                let shouldZoomBeHidden = selectedAnnotationView != nil
                exploreDelegate.toggleHeaderVisibility(visible: !shouldZoomBeHidden)
                exploreButtonStackView.isHidden = false
                trackingDimensionStackView.isHidden = false
                zoomSliderDrag.isEnabled = !shouldZoomBeHidden
                UIView.animate(withDuration: 0.2) {
                    self.exploreButtonStackView.alpha = shouldZoomBeHidden ? 0 : 1
                    self.trackingDimensionStackView.alpha = shouldZoomBeHidden ? 0 : 1
                    self.zoomSliderGradientImageView.alpha = shouldZoomBeHidden ? 0 : 0.3
                    self.titleBackgroundView.alpha = shouldZoomBeHidden ? 0 : 1
                } completion: { completed in
                    self.exploreButtonStackView.isHidden = shouldZoomBeHidden
                    self.trackingDimensionStackView.isHidden = shouldZoomBeHidden
                }
            }

        }
    }
    
    @IBOutlet weak var titleBackgroundView: UIView!
    @IBOutlet weak var profileBackgroundView: UIView!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var reloadButton: UIButton!
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
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        setupCustomTapGestureRecognizerOnMap()
        setupWhiteStatusBar()
        setupBlurredStatusBar()
        setupExploreMapButtons()
        setupSearchBar()
//        setupTrojansActiveView()
        
        self.exploreDelegate = self //mapViewController has an exploreDelegate, too. we'll set ourselves to that (as if we were the parentVC)
        self.postDelegate = self
        
        renderNewPostsOnMap(withType: .firstLoad)

        if let userLocation = locationManager.location {
            mapView.camera.centerCoordinate = userLocation.coordinate
            mapView.camera.centerCoordinateDistance = MapViewController.STARTING_ZOOM_DISTANCE
            mapView.camera.pitch = maxCameraPitch
        }
    }

    var accountBadgeHub: BadgeHub {
        let hub = BadgeHub(view: profileButton)
        hub.scaleCircleSize(by: 0.65) //match the bottm notification height
        hub.setCountLabelFont(UIFont(name: Constants.Font.Medium, size: 12))
        hub.setCircleColor(Constants.Color.mistLilacPurple, label: .white)
        return hub
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false) //for a better searchcontroller animation
        
        accountBadgeHub.setCount(DeviceService.shared.unreadMentionsCount())
        
        //Emoji keyboard autodismiss notification
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillDismiss(sender:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
        
        guard isFirstAppearance else { return }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moveMapLegalLabel()
                
        // Handle controller being exposed from push/present or pop/dismiss
        if (self.isMovingToParent || self.isBeingPresented){
            // Controller is being pushed on or presented.
        }
        else {
            // Controller is being shown as result of pop/dismiss/unwind.
            mySearchController.searchBar.becomeFirstResponder()
        }
        
        if let locationTapContext = ExploreMapViewController.locationTapContext {
            handleFeedLocationTap(lat: locationTapContext.lat, long: locationTapContext.long, postId: locationTapContext.postId)
            ExploreMapViewController.locationTapContext = nil
        }
        
        guard isFirstAppearance else { return }
        self.isFirstAppearance = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false) //for a better searchcontroller animation
    }
    
}

//MARK: - Setup

extension ExploreMapViewController {
    
//    func setupTrojansActiveView() {
//        trojansActiveView.isHidden = true //default. it's only unhidden for the home version
//        Task {
//            guard let usersCount = await UsersService.singleton.getTotalUsersCount() else {
//                DispatchQueue.main.async {
//                    self.trojansActiveView.isHidden = true
//                }
//                return
//            }
//            let hourOfDay = Calendar.current.component(.hour, from: Date())
//            let hourlyFactor = 1 - Double(abs(hourOfDay - 12)) * 0.01
//            let dayOfWeek = Calendar.current.component(.weekday, from: Date())
//            let dailyFactor = 1 - Double(abs(dayOfWeek-4)) * 0.02
//            let varied = Double(usersCount) * 2.0 * hourlyFactor * dailyFactor
//            await MainActor.run {
//                trojansActiveLabel.text = formattedVoteCount(Double(varied)) + " active"
//            }
//        }
//    }
    
    //MARK: - Helpers
    
    @MainActor
    func reloadAllData(animated: Bool = false) {
        fatalError("Not implemented yet")
    }
    
    func handleFeedLocationTap(lat: Double, long: Double, postId: Int) {
        slowFlyTo(lat: lat, long: long, incrementalZoom: false, withDuration: cameraAnimationDuration, allTheWayIn: true) { [self] completed in
            exploreDelegate.refreshMapPosts() { [self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
                    guard let tappedPostAnnotation = postAnnotations.first(where: { $0.post.id == postId }) else { return }
                    let tappedPostCluster = mapView.greatestClusterContaining(tappedPostAnnotation)
                    annotationSelectionType = .withoutPostCallout
    //                    print("SELECTING:", tappedPostCluster, tappedPostAnnotation)
                    mapView.selectAnnotation(tappedPostCluster ?? tappedPostAnnotation, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.annotationSelectionType = .normal
                    }
                    //Put the tapped post first in the cluster
                    //the below code could be replaced with a "put the post at the proper index in PostService, before rendering posts on map in refreshMapPosts()^
                    guard let cluster = tappedPostCluster,
                          let clusterView = mapView.view(for: cluster) as? ClusterAnnotationView
                    else { return }
                    guard let postIndex = clusterView.sortedMemberPosts.firstIndex(where: { $0.id == postId }) else { return }
                    let post = clusterView.sortedMemberPosts.remove(at: postIndex)
                    clusterView.sortedMemberPosts.insert(post, at: 0)
                    (clusterView.annotation as? MKClusterAnnotation)?.updateClusterTitle(newTitle: clusterView.sortedMemberPosts.first?.title)
                    clusterView.glyphText = post.topEmoji
                }
            }
        }
            
    }
}
//
//MARK: - Post Interaction

extension ExploreMapViewController {

    //The callout is currently presented, and we want to update the postView's UI with the new data
    func rerenderCollectionViewForUpdatedPostData() {
        guard let annotationView = selectedAnnotationView else { return }
        annotationView.rerenderCalloutForUpdatedPostData()
    }

    func movePostUpAfterEmojiKeyboardRaised() {
        guard let annotationView = selectedAnnotationView else { return }
        annotationView.movePostUpAfterEmojiKeyboardRaised()
    }

    func movePostBackDownAfterEmojiKeyboardDismissed() {
        guard let annotationView = selectedAnnotationView else { return }
        annotationView.movePostBackDownAfterEmojiKeyboardDismissed()
    }
}
