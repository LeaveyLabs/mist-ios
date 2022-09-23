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

class ExploreMapViewController: MapViewController {
    
    // UI
    let whiteStatusBar = UIImageView(image: UIImage.imageFromColor(color: .white))
    
    // Delegate
    var postDelegate: PostDelegate!
    var exploreDelegate: ExploreChildDelegate!
    
    //Flags
    var annotationSelectionType: AnnotationSelectionType = .normal
    var isFirstAppearance = true

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
                exploreDelegate.toggleNotchHiddenAndMinimum(hidden: shouldZoomBeHidden)
                exploreButtonStackView.isHidden = false
                trackingDimensionStackView.isHidden = false
                zoomSliderDrag.isEnabled = !shouldZoomBeHidden
                UIView.animate(withDuration: 0.2) {
                    self.exploreButtonStackView.alpha = shouldZoomBeHidden ? 0 : 1
                    self.trackingDimensionStackView.alpha = shouldZoomBeHidden ? 0 : 1
                    self.zoomSliderGradientImageView.alpha = shouldZoomBeHidden ? 0 : 0.3
                } completion: { completed in
                    self.exploreButtonStackView.isHidden = shouldZoomBeHidden
                    self.trackingDimensionStackView.isHidden = shouldZoomBeHidden
                }
            }

        }
    }
    
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
    
    func setupTrojansActiveView() {
        trojansActiveView.isHidden = true //default. it's only unhidden for the home version
        Task {
            guard let usersCount = await UsersService.singleton.getTotalUsersCount() else {
                DispatchQueue.main.async {
                    self.trojansActiveView.isHidden = true
                }
                return
            }
            let hourOfDay = Calendar.current.component(.hour, from: Date())
            let hourlyFactor = 1 - Double(abs(hourOfDay - 12)) * 0.01
            let dayOfWeek = Calendar.current.component(.weekday, from: Date())
            let dailyFactor = 1 - Double(abs(dayOfWeek-4)) * 0.02
            let varied = Double(usersCount) * 2.0 * hourlyFactor * dailyFactor
            await MainActor.run {
                trojansActiveLabel.text = formattedVoteCount(Double(varied)) + " active"
            }
        }
    }
    
    //MARK: - UserInteraction
    
    @IBAction func handleFilterButtonPress() {
        guard let parent = exploreDelegate as? HomeExploreParentViewController else { return }
        let filterVC = FeedFilterSheetViewController.create(delegate: parent)
        present(filterVC, animated: true)
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
