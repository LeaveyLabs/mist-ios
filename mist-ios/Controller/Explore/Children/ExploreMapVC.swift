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
        
    // CollectionView
    let centeredCollectionViewFlowLayout = CenteredCollectionViewFlowLayout()
    var collectionView: PostCollectionView!
    var currentlyVisiblePostIndex: Int?

    lazy var MAP_VIEW_WIDTH: Double = Double(mapView?.bounds.width ?? 350)
    lazy var POST_VIEW_WIDTH: Double = MAP_VIEW_WIDTH * 0.5 + 100
    lazy var POST_VIEW_MARGIN: Double = (MAP_VIEW_WIDTH - POST_VIEW_WIDTH) / 2
    lazy var POST_VIEW_MAX_HEIGHT: Double = (((mapView?.frame.height ?? 500) * 0.75) - 110.0)
    
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
//        setupCollectionView()

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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false) //for a better searchcontroller animation
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
    }
    
}

//MARK: - CollectionView

//extension ExploreMapViewController {
//
//    func toggleCollectionView(shouldBeHidden: Bool) {
////        exploreButtonStackView.isHidden = false
////        trackingDimensionStackView.isHidden = false
//        UIView.animate(withDuration: 0.2) {
//            self.collectionView.alpha = shouldBeHidden ? 0 : 1
//            self.exploreButtonStackView.alpha = shouldBeHidden ? 0 : 1
//            self.trackingDimensionStackView.alpha = shouldBeHidden ? 0 : 1
//            self.zoomSliderGradientImageView.alpha = shouldBeHidden ? 0 : 0.3
//            if shouldBeHidden {
//                self.trojansActiveView.alpha = 0
//            }
//        }
////    completion: { completed in
////            self.exploreButtonStackView.isHidden = shouldBeHidden
////            self.trackingDimensionStackView.isHidden = shouldBeHidden
////            if shouldBeHidden {
////                self.trojansActiveView.isHidden = true
////            }
////        }
//    }
//
//    func setupCollectionView() {
//        collectionView = PostCollectionView(centeredCollectionViewFlowLayout: centeredCollectionViewFlowLayout)
//        guard let collectionView = collectionView else { return }
//
//        collectionView.backgroundColor = UIColor.clear
//        collectionView.delegate = self
//        collectionView.dataSource = self
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        collectionView.clipsToBounds = false
//        view.addSubview(collectionView)
//
//        // register collection cells
//        collectionView.register( ClusterCarouselCell.self, forCellWithReuseIdentifier: String(describing: ClusterCarouselCell.self))
//
//        // configure layout
//        centeredCollectionViewFlowLayout.itemSize = CGSize(
//            width: POST_VIEW_WIDTH,
//            height: POST_VIEW_MAX_HEIGHT - 20
//        )
//        centeredCollectionViewFlowLayout.minimumLineSpacing = 16
//        collectionView.showsVerticalScrollIndicator = false
//        collectionView.showsHorizontalScrollIndicator = false
//
//        //SHOOOOTTTT: okay i got an error for constraining collectionView's width to the mapview because collection view (and its parent) werent a part of the mapview yet. so the annotation was clicked on too soon before it was even properly added to the map view
//        NSLayoutConstraint.activate([
//            collectionView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -60),
//            collectionView.widthAnchor.constraint(equalToConstant: MAP_VIEW_WIDTH),
//            collectionView.heightAnchor.constraint(equalToConstant: POST_VIEW_MAX_HEIGHT + 15), //15 for the bottom arrow
//            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
//        ])
//
//        if let previouslyVisiblePostIndex = currentlyVisiblePostIndex {
//            print(previouslyVisiblePostIndex)
//            collectionView.setNeedsLayout()
//            collectionView.layoutIfNeeded()
//            let index = IndexPath(item: previouslyVisiblePostIndex, section: 0)
//            collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: false)
//        } else {
//            currentlyVisiblePostIndex = 0
//        }
//        collectionView.alpha = 0
//        collectionView.isHidden = true
//        collectionView.fadeIn(duration: 0.1, delay: 0)
//    }
//
////    private func detectNeighboringPostTap(pointInMapView: CGPoint) -> Bool {
////        guard let currentpage = centeredCollectionViewFlowLayout.currentCenteredPage,
////              let maxPages = memberCount else { return false }
////        if pointInMapView.x > POST_VIEW_WIDTH + POST_VIEW_MARGIN, currentpage < maxPages - 1 {
////            centeredCollectionViewFlowLayout.scrollToPage(index: currentpage + 1, animated: true)
////            return true
////        } else if pointInMapView.x < POST_VIEW_MARGIN, currentpage >= 1 {
////            centeredCollectionViewFlowLayout.scrollToPage(index: currentpage - 1, animated: true)
////            return true
////        }
////        return false
////    }
//
//
//}
//
////MARK: - Responding to Post Interaction
//
//extension ExploreMapViewController {
//
//    //The callout is currently presented, and we want to update the postView's UI with the new data
//    func rerenderCalloutForUpdatedPostData() {
//        guard
//            let page = centeredCollectionViewFlowLayout.currentCenteredPage,
//            let postCollectionView = collectionView,
//            let postCarouselCell = postCollectionView.cellForItem(at: IndexPath(item: page, section: 0)) as? ClusterCarouselCell,
//            let _ = PostService.singleton.getPost(withPostId: postCarouselCell.postView.postId)
//        else {
//            return
//        }
//        postCollectionView.reloadItems(at: [IndexPath(item: page, section: 0)])
//    }
//
//    func movePostUpAfterEmojiKeyboardRaised() {
//        view.layoutIfNeeded()
//        UIView.animate(withDuration: 0.25) { [self] in
//            guard let index = currentlyVisiblePostIndex else { return }
//            let currentlyVisiblePostView = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as! ClusterCarouselCell
//            currentlyVisiblePostView.bottomConstraint.constant = -80
//            view.layoutIfNeeded()
////                constraints.first { $0.firstAnchor == collectionView?.bottomAnchor }?.constant = -152
////                layoutIfNeeded()
//        }
//    }
//
//    func movePostBackDownAfterEmojiKeyboardDismissed() {
//        view.layoutIfNeeded()
//        UIView.animate(withDuration: 0.25) { [self] in
//            guard let index = currentlyVisiblePostIndex else { return }
//            let currentlyVisiblePostView = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as! ClusterCarouselCell
//            currentlyVisiblePostView.bottomConstraint.constant = -15
//            view.layoutIfNeeded()
//
//            //old method
////            self?.constraints.first { $0.firstAnchor == self?.collectionView?.bottomAnchor }?.constant = -70
////            self?.layoutIfNeeded()
//        }
//    }
//
//}
//
////These are not being called for some reason
//extension ExploreMapViewController: UICollectionViewDelegate {
//
//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        view.endEditing(true)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
//        print("should")
//        return true
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        print("Selected Cell #\(indexPath.row)")
//        if let currentCenteredPage = centeredCollectionViewFlowLayout.currentCenteredPage,
//            currentCenteredPage != indexPath.row {
//            centeredCollectionViewFlowLayout.scrollToPage(index: indexPath.row, animated: true)
//        }
//    }
//
//}
//
////MARK: - CollectionViewDataSource
//
//extension ExploreMapViewController: UICollectionViewDataSource {
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return exploreDelegate.posts.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ClusterCarouselCell.self), for: indexPath) as! ClusterCarouselCell
//        let cachedPost = PostService.singleton.getPost(withPostId: exploreDelegate.posts[indexPath.item].id)!
//        cell.configureForPost(post: cachedPost, nestedPostViewDelegate: postDelegate, bubbleTrianglePosition: .bottom)
//
//        return cell
//    }
//
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        print("Did end decelerating. Current centered index: \(String(describing: centeredCollectionViewFlowLayout.currentCenteredPage ?? nil))")
//        currentlyVisiblePostIndex = centeredCollectionViewFlowLayout.currentCenteredPage
//    }
//
//    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        print("Did end animation. Current centered index: \(String(describing: centeredCollectionViewFlowLayout.currentCenteredPage ?? nil))")
//        currentlyVisiblePostIndex = centeredCollectionViewFlowLayout.currentCenteredPage
//    }
//}
//
