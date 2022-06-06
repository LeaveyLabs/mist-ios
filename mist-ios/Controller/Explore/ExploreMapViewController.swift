//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

class ExploreMapViewController: MapViewController {

    // MARK: - Properties
    @IBOutlet weak var mistTitle: UIView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var featuredIconButton: UIButton!
        
    // ExploreViewController
    var mySearchController: UISearchController!
    var resultsTableController: LiveResultsTableViewController!
    var filterMapModalVC: FilterViewController?

    // PostsService
    var postsService: PostsService!
    var postFilter = PostFilter()
    
    var handlingSubmission = false // handleNewslySubmittedPost sets this flag for mapViewDidSelectView

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        latitudeOffset = 0.00095
        navigationItem.titleView = mistTitle
        setupFilterButton()
        setupSearchBar()
        setupMapGestureRecognizers()
        setupPostsService()
        reloadPosts()
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //TODO: pull up search bar when returning to this VC after search via search button click
        //https://stackoverflow.com/questions/27951965/cannot-set-searchbar-as-firstresponder
    }
    
    //MARK: - Setup
    
    func setupPostsService() {
        postsService = PostsService()
        postsService.setFilter(to: postFilter)
    }
    
    func setupFilterButton() {
        updateFilterButtonLabel()
        filterButton.layer.cornerRadius = 10
        applyShadowOnView(filterButton)
    }
    
    func setupMapGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userInteractedWithMap))
        tapGestureRecognizer.delaysTouchesBegan = false
        tapGestureRecognizer.delaysTouchesEnded = false
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: - User Interaction
    
    @IBAction func filterButtonDidTapped(_ sender: UIButton) {
        dismissPost()
        if let filterMapModalVC = filterMapModalVC {
            filterMapModalVC.dismiss(animated: true)
        } else {
            filterMapModalVC = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Filter) as? FilterViewController
            if let filterMapModalVC = filterMapModalVC {
                filterMapModalVC.selectedFilter = postFilter
                filterMapModalVC.delegate = self
                filterMapModalVC.sheetDismissDelegate = self
                filterMapModalVC.selectedFilter = postFilter
                filterMapModalVC.loadViewIfNeeded() //doesnt work without this function call
                present(filterMapModalVC, animated: true)
            }
        }
    }
    
    @IBAction func exploreUserTrackingButtonDidPressed(_ sender: UIButton) {
        dismissPost()
        dismissFilter()
        userTrackingButtonDidPressed(sender)
    }
    
    @IBAction func exploreMapDimensionButtonDidPressed(_ sender: UIButton) {
        dismissPost()
        dismissFilter()
        mapDimensionButtonDidPressed(sender)
    }
    
    @IBAction func exploreZoomInButtonDidPressed(_ sender: UIButton) {
        dismissPost()
        dismissFilter()
        zoomInButtonDidPressed(sender)
    }
    
    @IBAction func exploreZoomOutButtonDidPressed(_ sender: UIButton) {
        dismissPost()
        dismissFilter()
        zoomOutButtonDidPressed(sender)
    }
    
    // This handles the case of tapping, but not panning and dragging for some reason
    @objc func userInteractedWithMap() {
        print("Handling ExploreMapView tap with a gesture recognizer")
        if (sheetPresentationController?.selectedDetentIdentifier?.rawValue != "xs") {
            //TODO: don't execute this code if you clicked on an existing annotation
            deselectOneAnnotationIfItExists() //annotation will still be deselected without this, but the animation looks better if deselection occurs before togglesheetsisze
            dismissFilter()
        }
    }
    
    //MARK: - Helpers
    
    func updateFilterButtonLabel() {
        filterButton.setAttributedTitle(PostFilter.getFilterLabelText(for: postFilter), for: .normal)
        if postFilter.postType == .Featured {
//            featuredIconButton.isHidden = false
        } else {
//            featuredIconButton.isHidden = true
        }
    }
    
    func dismissPost() {
        deselectOneAnnotationIfItExists()
    }
    
    func dismissFilter() {
        //if you want to dismiss on drag/pan, first toggle sheet size, then make filterMapModalVC.dismiss a completion of toggleSheetSize
        filterMapModalVC?.dismiss(animated: true)
    }
    
    // To make the map fly directly to the middle of cluster locations...
    // After loading the annotations for the map, immediately center the camera around the annotation
    // (as if it had flown there), check if it's an annotation, then set the camera back to USC
    func handleNewlySubmittedPost(_ newPost: Post) {
        handlingSubmission = true
        if let newPostAnnotation = displayedAnnotations.first(where: { postAnnotation in
            postAnnotation.post == newPost
        }) {
            slowFlyTo(lat: newPostAnnotation.coordinate.latitude + latitudeOffset,
                      long: newPostAnnotation.coordinate.longitude,
                      incrementalZoom: false,
                      withDuration: cameraAnimationDuration+2,
                      completion: { [self] _ in
                mapView.selectAnnotation(newPostAnnotation, animated: true)
            })
        }
    }
    
    func handleClusterAnnotationSelection(_ clusterAnnotation: MKClusterAnnotation) {
        let wasHotspotBeforeSlowFly = clusterAnnotation.isHotspot
        slowFlyTo(lat: clusterAnnotation.coordinate.latitude,
                  long: clusterAnnotation.coordinate.longitude,
                  incrementalZoom: true,
                  withDuration: cameraAnimationDuration,
                  completion: { _ in
            if wasHotspotBeforeSlowFly {
                var posts = [Post]()
                for annotation in clusterAnnotation.memberAnnotations {
                    if let annotation = annotation as? PostAnnotation {
                        posts.append(annotation.post)
                    }
                }
                let newVC = ResultsFeedViewController.resultsFeedViewController(feedType: .hotspot,
                                                                                feedValue: clusterAnnotation.title!)
                newVC.posts = posts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.navigationController?.pushViewController(newVC, animated: true)
                }
            } else {

            }
        })

    }
    
    //MARK: - DB Interaction
    
    func reloadPosts() {
        Task {
            do {
                let loadedPosts = try await postsService.newPosts()
                
                let maxPostsToDisplay = 10000
                displayedAnnotations = []
                if loadedPosts.count > 0 {
                    for index in 0...min(maxPostsToDisplay, loadedPosts.count-1) {
                        let postAnnotation = PostAnnotation(withPost: loadedPosts[index])
                        displayedAnnotations.append(postAnnotation)
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    func reloadPosts(afterReload: @escaping () -> Void?) {
        Task {
            do {
                let loadedPosts = try await postsService.newPosts()
                
                //Can this be handled by postsService instead?
                let maxPostsToDisplay = 10000
                displayedAnnotations = []
                if loadedPosts.count > 0 {
                    for index in 0...min(maxPostsToDisplay, loadedPosts.count-1) {
                        let postAnnotation = PostAnnotation(withPost: loadedPosts[index])
                        displayedAnnotations.append(postAnnotation)
                    }
                }
                afterReload()
            } catch {
                print(error)
            }
        }
    }
    
}

//MARK: - MapDelegate

extension ExploreMapViewController {
        
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.isZoomEnabled = true // AnnotationQuickSelect: 3 of 3, just in case
        dismissFilter()
        if handlingSubmission {
            handlingSubmission = false
            if let clusterAnntation = view.cluster?.annotation as? MKClusterAnnotation {
                mapView.deselectAnnotation(view.annotation, animated: false)
                handleClusterAnnotationSelection(clusterAnntation)
            } else if let postAnnotationView = view as? PostAnnotationView {
                postAnnotationView.loadPostView(on: mapView,
                                                withDelay: 0,
                                                withPostDelegate: self)
            }
        }
        else if view.annotation is MKUserLocation {
            mapView.deselectAnnotation(view.annotation, animated: false)
            mapView.userLocation.title = "Hey cutie"
        }
        else if let clusterAnnotation = view.annotation as? MKClusterAnnotation {
            print("SELECTED CLUSTER")
            mapView.deselectAnnotation(view.annotation, animated: false)
            handleClusterAnnotationSelection(clusterAnnotation)
        }
        
        //OH SHIT: here's the issue
        //click on a postAnnotation from afar
        //while zooming in, annotations in another cluster turn into a new cluster WITH the annotation you're currently zooming in on
        //hmmm... ideally, we could 
        
        else if let postAnnotationView = view as? PostAnnotationView {
            print("SELECTED POST")
            slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset,
                      long: view.annotation!.coordinate.longitude,
                      incrementalZoom: false,
                      withDuration: cameraAnimationDuration,
                      completion: { _ in })
            postAnnotationView.loadPostView(on: mapView,
                                            withDelay: cameraAnimationDuration,
                                            withPostDelegate: self)
        }
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("deselected")
    }
    
    override func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        super.mapViewDidChangeVisibleRegion(mapView)
        
        //If you want to dismiss on drag/pan, then fix this code
//        if !cameraIsFlying {
//            print(sheetPresentationController?.selectedDetentIdentifier)
//            if sheetPresentationController?.selectedDetentIdentifier != nil && sheetPresentationController?.selectedDetentIdentifier?.rawValue != "zil" {
//                dismissFilter()
//            }
//        }
    }
    
    // I believe this code is outdated
//    func mapAnnotationDidTouched(_ sender: UIButton) {
//        let filterMapModalVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.SortBy) as! SortByViewController
//        if let sheet = filterMapModalVC.sheetPresentationController {
//            sheet.detents = [.medium()]
//            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
//            sheet.prefersGrabberVisible = true
//            sheet.largestUndimmedDetentIdentifier = .medium
//        }
//        present(filterMapModalVC, animated: true, completion: nil)
//    }
     
    // This could be useful for managing cluster behavior
//    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
//        
//    }
    
}

extension ExploreMapViewController: FilterDelegate {
    
    func handleUpdatedFilter(_ newPostFilter: PostFilter, shouldReload: Bool, _ afterFilterUpdate: @escaping () -> Void) {
    
        //Should eventually remove one of these two and have filter just saved in one location
        postsService.setFilter(to: newPostFilter)
        postFilter = newPostFilter
        
        updateFilterButtonLabel()
        
        if shouldReload {
            reloadPosts(afterReload: afterFilterUpdate)
        }
    }
        
}

extension ExploreMapViewController: childDismissDelegate {
    func handleChildWillDismiss() {
        
    }

    func handleChildDidDismiss() {
        print("sheet dismissed")
        filterMapModalVC = nil
    }
}

//MARK: - Post Delegation

extension ExploreMapViewController: PostDelegate, ShareActivityDelegate {
    
    func backgroundDidTapped(post: Post) {
        sendToPostViewFor(post, withRaisedKeyboard: false)
    }
    
    func commentDidTapped(post: Post) {
        sendToPostViewFor(post, withRaisedKeyboard: true)
    }
    
    func moreDidTapped(post: Post) {
        let moreVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.More) as! MoreViewController
        moreVC.loadViewIfNeeded() //doesnt work without this function call
        moreVC.shareDelegate = self
        present(moreVC, animated: true)
    }
    
    func dmDidTapped(post: Post) {
        let newMessageNavVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewMessageNavigation) as! UINavigationController
        newMessageNavVC.modalPresentationStyle = .fullScreen
        present(newMessageNavVC, animated: true, completion: nil)
    }
    
    func favoriteDidTapped(post: Post) {
        //do something
    }
    
    func likeDidTapped(post: Post) {
        //do something
    }
    
    // ShareActivityDelegate
    func presentShareActivityVC() {
        if let url = NSURL(string: "https://www.getmist.app")  {
            let objectsToShare: [Any] = [url]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            present(activityVC, animated: true)
        }
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
