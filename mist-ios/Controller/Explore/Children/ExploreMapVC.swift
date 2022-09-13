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
    
    var selectedAnnotationView: AnnotationViewWithPosts?
    
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
        setupCollectionView()

        if let userLocation = locationManager.location {
            mapView.camera.centerCoordinate = userLocation.coordinate
            mapView.camera.centerCoordinateDistance = MapViewController.STARTING_ZOOM_DISTANCE
            mapView.camera.pitch = maxCameraPitch
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false) //for a better searchcontroller animation
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moveMapLegalLabel()
        
        mapView.selectAnnotation(postAnnotations.first!, animated: true)
        
        // Handle controller being exposed from push/present or pop/dismiss
        if (self.isMovingToParent || self.isBeingPresented){
            // Controller is being pushed on or presented.
        }
        else {
            // Controller is being shown as result of pop/dismiss/unwind.
            mySearchController.searchBar.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false) //for a better searchcontroller animation
    }
    
}

//MARK: - Setup

extension ExploreMapViewController {
    
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
    
    func setupCollectionView() {
        collectionView = PostCollectionView(centeredCollectionViewFlowLayout: centeredCollectionViewFlowLayout)
        guard let collectionView = collectionView else { return }

        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.clipsToBounds = false
        view.addSubview(collectionView)

        // register collection cells
        collectionView.register( ClusterCarouselCell.self, forCellWithReuseIdentifier: String(describing: ClusterCarouselCell.self))

        // configure layout
        centeredCollectionViewFlowLayout.itemSize = CGSize(
            width: POST_VIEW_WIDTH + 20,
            height: POST_VIEW_MAX_HEIGHT - 20
        )
        centeredCollectionViewFlowLayout.minimumLineSpacing = 25
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false

        NSLayoutConstraint.activate([
            collectionView.centerYAnchor.constraint(equalTo: mapView.centerYAnchor, constant: -60),
            collectionView.widthAnchor.constraint(equalTo: mapView.widthAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: POST_VIEW_MAX_HEIGHT + 15), //15 for the bottom arrow
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
        ])
        
//        collectionView.backgroundColor = .black.withAlphaComponent(0.1)
        collectionView.alpha = 0
    }
}

//MARK: - CollectionViewHelpers

extension ExploreMapViewController {

    //When this function is called with FALSE, we are confident we have:
        //1 a selectedAnnotationView
    func toggleCollectionView(shouldBeHidden: Bool) {
        guard collectionView != nil else { return } //collectionView is not set even though map didChangeVisibleRegion is called
        
        print("TOGGLING COLLECITON VIEW")
        if shouldBeHidden {
            guard collectionView.alpha != 0 else { return }
            selectedAnnotationView = nil
            currentlyVisiblePostIndex = nil
        } else {
            guard collectionView.alpha == 0 else { return }
            guard let selectedAnnotationView = selectedAnnotationView else {
                fatalError("must have a selected annotation view before rendering colleciton view!")
            }
            // We need to scroll to page for the selected annotation view
            let postIndexToBeVisible: Int
            if let clusterView = selectedAnnotationView as? ClusterAnnotationView {
                //choose the first member annotation. it's probably not going to be the right one
                //TODO: more ideally: each cluster contains a sorted array of member annotations in the exact same assortment as sortedAnnotations, and it does this sorting in the background whenever it's changed
                let someRandomMemberAnnotation = (clusterView.annotation as! MKClusterAnnotation).memberAnnotations.first { $0 is PostAnnotation }
                
                //find the random member annotation's location in the sorted array
                postIndexToBeVisible = postAnnotations.firstIndex(of: someRandomMemberAnnotation as! PostAnnotation)!
                }
            else if let postAnnotationView = selectedAnnotationView as? PostAnnotationView {
                postIndexToBeVisible = postAnnotations.firstIndex(of: postAnnotationView.annotation as! PostAnnotation)!
            } else { //place annotation?
                postIndexToBeVisible = 6969696
            }
            centeredCollectionViewFlowLayout.scrollToPage(index: postIndexToBeVisible, animated: false)
        }
        
        print("ANIMATING TRUE")
        UIView.animate(withDuration: 0.2) {
            self.collectionView.alpha = shouldBeHidden ? 0 : 1
            self.exploreButtonStackView.alpha = shouldBeHidden ? 0 : 1
            self.trackingDimensionStackView.alpha = shouldBeHidden ? 0 : 1
            self.zoomSliderGradientImageView.alpha = shouldBeHidden ? 0 : 0.3
            if shouldBeHidden {
                self.trojansActiveView.alpha = 0
            }
        }
        
        collectionView.reloadData()
        
    }

//    private func detectNeighboringPostTap(pointInMapView: CGPoint) -> Bool {
//        guard let currentpage = centeredCollectionViewFlowLayout.currentCenteredPage,
//              let maxPages = memberCount else { return false }
//        if pointInMapView.x > POST_VIEW_WIDTH + POST_VIEW_MARGIN, currentpage < maxPages - 1 {
//            centeredCollectionViewFlowLayout.scrollToPage(index: currentpage + 1, animated: true)
//            return true
//        } else if pointInMapView.x < POST_VIEW_MARGIN, currentpage >= 1 {
//            centeredCollectionViewFlowLayout.scrollToPage(index: currentpage - 1, animated: true)
//            return true
//        }
//        return false
//    }
    
    
    func updateCenteredPageAndReloadVisibleIndexLabel() {
        if let centeredPage = centeredCollectionViewFlowLayout.currentCenteredPage {
            currentlyVisiblePostIndex = centeredPage
        }
    }
    
    //this function is called whenever currentCenteredPostIndex is updated
    func handleSwipeToCenteredPage() {
        guard let currentIndex = currentlyVisiblePostIndex else { return }
        let postAnnotationToBeCentered = postAnnotations[currentIndex]
        
        //TODO: it might be best to first slow fly, and then to select, kinda like how we do on a newpost
        annotationSelectionType = .swipe
        
        //WTF?
        //we found a clusterAnnotationView from this function, but the cluster had no "annotation" property
        if let cluster = mapView.greatestClusterContaining(postAnnotationToBeCentered) {
            mapView.selectAnnotation(cluster, animated: true)
        } else {
            mapView.selectAnnotation(postAnnotationToBeCentered, animated: true)
        }
    }

}

//MARK: - CollectionViewDelegate

//These are not being called for some reason
extension ExploreMapViewController: UICollectionViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        print("should select")
        return true
    }

//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        print("did select. cell #\(indexPath.row)")
//        if let currentCenteredPage = centeredCollectionViewFlowLayout.currentCenteredPage,
//            currentCenteredPage != indexPath.row {
//            centeredCollectionViewFlowLayout.scrollToPage(index: indexPath.row, animated: true)
//        }
//    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !collectionView.isTracking else { return }
        if currentlyVisiblePostIndex != centeredCollectionViewFlowLayout.currentCenteredPage {
            handleSwipeToCenteredPage()
        }
        currentlyVisiblePostIndex = centeredCollectionViewFlowLayout.currentCenteredPage
        
    }
    
    

}

//MARK: - CollectionViewDataSource

extension ExploreMapViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("POST ANNOTATIONS COUNT:", postAnnotations.count)
        return postAnnotations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ClusterCarouselCell.self), for: indexPath) as! ClusterCarouselCell
        let cachedPost = PostService.singleton.getPost(withPostId: postAnnotations[indexPath.item].post.id)!
        cell.configureForPost(post: cachedPost, nestedPostViewDelegate: postDelegate, bubbleTrianglePosition: .bottom)

        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("Did end decelerating. Current centered index: \(String(describing: centeredCollectionViewFlowLayout.currentCenteredPage ?? nil))")
        currentlyVisiblePostIndex = centeredCollectionViewFlowLayout.currentCenteredPage
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("Did end animation. Current centered index: \(String(describing: centeredCollectionViewFlowLayout.currentCenteredPage ?? nil))")
        currentlyVisiblePostIndex = centeredCollectionViewFlowLayout.currentCenteredPage
    }
    
}

//MARK: - Post Interaction

extension ExploreMapViewController {

    //The callout is currently presented, and we want to update the postView's UI with the new data
    func rerenderCollectionViewForUpdatedPostData() {
        guard
            let page = centeredCollectionViewFlowLayout.currentCenteredPage,
            let postCollectionView = collectionView,
            let postCarouselCell = postCollectionView.cellForItem(at: IndexPath(item: page, section: 0)) as? ClusterCarouselCell,
            let _ = PostService.singleton.getPost(withPostId: postCarouselCell.postView.postId)
        else {
            return
        }
        postCollectionView.reloadItems(at: [IndexPath(item: page, section: 0)])
    }

    func movePostUpAfterEmojiKeyboardRaised() {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [self] in
            guard let index = currentlyVisiblePostIndex else { return }
            let currentlyVisiblePostView = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as! ClusterCarouselCell
            currentlyVisiblePostView.bottomConstraint.constant = -80
            view.layoutIfNeeded()
//                constraints.first { $0.firstAnchor == collectionView?.bottomAnchor }?.constant = -152
//                layoutIfNeeded()
        }
    }

    func movePostBackDownAfterEmojiKeyboardDismissed() {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [self] in
            guard let index = currentlyVisiblePostIndex else { return }
            let currentlyVisiblePostView = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as! ClusterCarouselCell
            currentlyVisiblePostView.bottomConstraint.constant = -15
            view.layoutIfNeeded()

            //old method
//            self?.constraints.first { $0.firstAnchor == self?.collectionView?.bottomAnchor }?.constant = -70
//            self?.layoutIfNeeded()
        }
    }

}
