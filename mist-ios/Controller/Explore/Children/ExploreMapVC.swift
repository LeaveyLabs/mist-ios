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
    var isFirstAppearance = true
        
    // CollectionView
    let centeredCollectionViewFlowLayout = CenteredCollectionViewFlowLayout()
    var collectionView: PostCollectionView!
    var currentlyVisiblePostIndex: Int?

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
//                zoomStackView.isHidden = false
                exploreButtonStackView.isHidden = false
                trackingDimensionStackView.isHidden = false
                zoomSlider.isEnabled = !shouldZoomBeHidden
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false) //for a better searchcontroller animation
        
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
        
        
        guard isFirstAppearance else { return }
        let firstAnnotation: MKAnnotation = mapView.greatestClusterContaining(postAnnotations.first!) ?? postAnnotations.first!
        mapView.camera.centerCoordinate = firstAnnotation.coordinate
//        slowFlyTo(lat: firstAnnotation.coordinate.latitude, long: firstAnnotation.coordinate.longitude, incrementalZoom: false, withDuration: 0, withLatitudeOffset: true, completion: { completed in
            self.mapView.selectAnnotation(firstAnnotation, animated: true)
//        })
        isFirstAppearance = false
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
}
//
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
