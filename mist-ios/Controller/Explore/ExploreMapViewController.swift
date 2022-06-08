//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

enum AnnotationSelectionType {
    case submission, swipe, normal
}

class ExploreMapViewController: MapViewController {

    // MARK: - Properties
    @IBOutlet weak var mistTitle: UIView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var featuredIconButton: UIButton!
            
    // ExploreViewController
    var mySearchController: UISearchController!
    var resultsTableController: LiveResultsTableViewController!
    var filterMapModalVC: FilterViewController?
    
    var selectedAnnotationView: MKAnnotationView?
    var selectedAnnotationIndex: Int? {
        guard let selected = selectedAnnotationView else { return nil }
        return postAnnotations.firstIndex(of: selected.annotation as! PostAnnotation)
    }

    // Post Loading
    var postFilter = PostFilter()
    
    // Flag for didSelect(annotation)
    var annotationSelectionType: AnnotationSelectionType = .normal

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        latitudeOffset = 0.00095
        navigationItem.titleView = mistTitle
        setupFilterButton()
        setupSearchBar()
        setupCustomTapGestureRecognizerOnMap()
        renderInitialPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //TODO: pull up search bar when returning to this VC after search via search button click
        //https://stackoverflow.com/questions/27951965/cannot-set-searchbar-as-firstresponder
    }
    
    func setupFilterButton() {
        updateFilterButtonLabel()
        filterButton.layer.cornerRadius = 10
        applyShadowOnView(filterButton)
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
    
    //MARK: AnnotationViewInteractionDelayPrevention

    // Allows for noticeably faster zooms to the annotationview
    // Turns isZoomEnabled off and on immediately before and after a click on the map.
    // This means that in case the tap happened to be on an annotation, there's less delay.
    // Downside: double tap features are not possible
    //https://stackoverflow.com/questions/35639388/tapping-an-mkannotation-to-select-it-is-really-slow
    // Note: even though it would make the most sense for the tap gesture to live on the annotationView,
    // when that's the case, some clicks NEAR but not ON the annotation view result in a delay.
    // We want 0 delays, so we're putting it on the mapView
        
    func setupCustomTapGestureRecognizerOnMap() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.delaysTouchesBegan = false
        tapRecognizer.delaysTouchesEnded = false
        mapView.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        // AnnotationViewInteractionDelayPrevention 1 of 2
        mapView.isZoomEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.mapView.isZoomEnabled = true
        }
        
        // Handle other purposes of the tap gesture besides just AnnotationViewInteractionDelayPrevention:
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
        annotationSelectionType = .submission
        if let newPostAnnotation = postAnnotations.first(where: { postAnnotation in
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
                let newVC = ResultsFeedViewController.resultsFeedViewController(feedType: .hotspot, feedValue: clusterAnnotation.title!)
                newVC.posts = posts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.navigationController?.pushViewController(newVC, animated: true)
                }
            } else {

            }
        })

    }
    
    //MARK: - Getting posts
    
    func renderInitialPosts() {
        renderPostsAsAnnotations(PostsService.initialPosts)
    }
    
    func reloadPosts() {
        Task {
            do {
                let loadedPosts = try await PostsService.newPosts()
                renderPostsAsAnnotations(loadedPosts)
            } catch {
                CustomSwiftMessages.showError(errorDescription: error.localizedDescription)
            }
        }
    }
    
    func reloadPosts(afterReload: @escaping () -> Void?) {
        Task {
            do {
                let loadedPosts = try await PostsService.newPosts()
                renderPostsAsAnnotations(loadedPosts)
                afterReload()
            } catch {
                CustomSwiftMessages.showError(errorDescription: error.localizedDescription)
            }
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

//MARK: - MapDelegate

extension ExploreMapViewController {
        
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation {
            mapView.deselectAnnotation(view.annotation, animated: false)
            mapView.userLocation.title = "Hey cutie"
        }
        
        selectedAnnotationView = view
        mapView.isZoomEnabled = true // AnnotationQuickSelect: 3 of 3, just in case
        dismissFilter()
        switch annotationSelectionType {
        case .swipe:
            if let clusterAnnotation = view.cluster?.annotation as? MKClusterAnnotation {
                mapView.deselectAnnotation(view.annotation, animated: false)
                handleClusterAnnotationSelection(clusterAnnotation)
            } else if let postAnnotationView = view as? PostAnnotationView {
                slowFlyOutAndIn(lat: view.annotation!.coordinate.latitude + latitudeOffset,
                          long: view.annotation!.coordinate.longitude,
                          withDuration: cameraAnimationDuration,
                          completion: { _ in })
                postAnnotationView.loadPostView(on: mapView,
                                                withDelay: cameraAnimationDuration * 4,
                                                withPostDelegate: self)
            }
        case .submission:
            if let clusterAnnotation = view.cluster?.annotation as? MKClusterAnnotation {
                mapView.deselectAnnotation(view.annotation, animated: false)
                handleClusterAnnotationSelection(clusterAnnotation)
            } else if let postAnnotationView = view as? PostAnnotationView {
                postAnnotationView.loadPostView(on: mapView,
                                                withDelay: 0,
                                                withPostDelegate: self)
            }
        default:
            if let clusterAnnotation = view.annotation as? MKClusterAnnotation {
                mapView.deselectAnnotation(view.annotation, animated: false)
                handleClusterAnnotationSelection(clusterAnnotation)
            } else if let postAnnotationView = view as? PostAnnotationView {
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
        annotationSelectionType = .normal // Return to default
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        selectedAnnotationView = nil
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

//Swipe gestures

extension ExploreMapViewController: AnnotationViewSwipeDelegate {

    func handlePostViewSwipeRight() {
        guard var index = selectedAnnotationIndex else { return }

        deselectOneAnnotationIfItExists()
        index += 1
        if index == postAnnotations.count {
            index = 0
        }
        let nextAnnotation = postAnnotations[index]
        annotationSelectionType = .swipe
        mapView.selectAnnotation(nextAnnotation, animated: true)
    }
    
    func handlePostViewSwipeLeft() {
        guard var index = selectedAnnotationIndex else { return }
        
        let pav = selectedAnnotationView as! PostAnnotationView
        let postView = pav.postCalloutView!
        
//        postView.animation = "slideLeft"
//        postView.duration = 2
//        postView.rever

        deselectOneAnnotationIfItExists()
        index -= 1
        if index == -1 {
            index = postAnnotations.count-1
        }
        let nextAnnotation = postAnnotations[index]
        annotationSelectionType = .swipe
        mapView.selectAnnotation(nextAnnotation, animated: true)
    }
    
}
