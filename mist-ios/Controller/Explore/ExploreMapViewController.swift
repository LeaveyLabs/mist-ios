//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit
import AVFAudio

///reference for search controllers
///https://developer.apple.com/documentation/uikit/view_controllers/using_suggested_searches_with_a_search_controller
///https://developer.apple.com/documentation/uikit/view_controllers/displaying_searchable_content_by_using_a_search_controller
///

let POST_VIEW_TAG = 999

class ExploreMapViewController: MapViewController {

    // MARK: - Properties
    @IBOutlet weak var mistTitle: UIView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var featuredIconButton: UIButton!
        
    // ExploreViewController
    var mySearchController: UISearchController!
    private var resultsTableController: LiveResultsTableViewController!
    var filterMapModalVC: FilterViewController?

    // PostsService
    var postsService: PostsService!
    var postFilter = PostFilter()
    
    var handlingSubmission = false // handleNewslySubmittedPost sets this flag for mapViewDidSelectView

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        latitudeOffset = 0.00095
        navigationItem.titleView = mistTitle
                
        updateFilterButtonLabel()
        filterButton.layer.cornerRadius = 10
        applyShadowOnView(filterButton)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userInteractedWithMap))
        mapView.addGestureRecognizer(tapGestureRecognizer)
        
        setupSearchBar()
        setupPostsService()
        reloadPosts()

        cameraIsFlying = true //camera is adjusted during setup
        super.viewDidLoad()
        cameraIsFlying = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //TODO: pull up search bar when returning to this VC after search via search button click
        //https://stackoverflow.com/questions/27951965/cannot-set-searchbar-as-firstresponder
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        dismissPost()
    }
    
    //MARK: - Setup
    
    func setupPostsService() {
        postsService = PostsService()
        postsService.setFilter(to: postFilter)
    }
    
    //MARK: - User Interaction
    
    @IBAction func filterButtonDidTapped(_ sender: UIButton) {
        dismissPost()
        if let filterMapModalVC = filterMapModalVC {
            filterMapModalVC.dismiss(animated: true)
        } else {
            filterMapModalVC = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Filter) as! FilterViewController
            filterMapModalVC?.selectedFilter = postFilter
            filterMapModalVC!.delegate = self
            filterMapModalVC!.sheetDismissDelegate = self
            filterMapModalVC!.selectedFilter = postFilter
            filterMapModalVC!.loadViewIfNeeded() //doesnt work without this function call
            present(filterMapModalVC!, animated: true)
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
    
    // This handles the case of tapping, but not panning and dragging for some reason
    @objc func userInteractedWithMap() {
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
        if clusterAnnotation.isHotspot {
            var posts = [Post]()
            for annotation in clusterAnnotation.memberAnnotations {
                if let annotation = annotation as? PostAnnotation {
                    posts.append(annotation.post)
                }
            }
            let newVC = ResultsFeedViewController.resultsFeedViewController(feedType: .hotspot,
                                                                            feedValue: clusterAnnotation.title!)
            newVC.posts = posts
            navigationController?.pushViewController(newVC, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in //wait 0.5 seconds
                centerMapOn(lat: clusterAnnotation.coordinate.latitude,
                            long: clusterAnnotation.coordinate.longitude)
            }
        } else {
            slowFlyTo(lat: clusterAnnotation.coordinate.latitude,
                      long: clusterAnnotation.coordinate.longitude,
                      incrementalZoom: true,
                      withDuration: cameraAnimationDuration,
                      completion: { _ in })
        }
    }
    
    
    //MARK: - MapDelegate
        
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        dismissFilter()
        if handlingSubmission {
            handlingSubmission = false
            if let clusterAnntation = view.cluster?.annotation as? MKClusterAnnotation {
                mapView.deselectAnnotation(view.annotation, animated: false)
                handleClusterAnnotationSelection(clusterAnntation)
            } else if let view = view as? PostMarkerAnnotationView {
                view.glyphTintColor = mistUIColor() //this is needed bc for some reason the glyph tint color turns grey even with the mist-heart-pink icon
                view.markerTintColor = mistSecondaryUIColor()
                loadPostViewFor(postAnnotationView: view,
                                withDelay: 0)
            }
        }
        else if view.annotation is MKUserLocation {
            mapView.deselectAnnotation(view.annotation, animated: false)
            mapView.userLocation.title = "Hey cutie"
        }
        else if let clusterAnnotation = view.annotation as? MKClusterAnnotation {
            mapView.deselectAnnotation(view.annotation, animated: false)
            handleClusterAnnotationSelection(clusterAnnotation)
        }
        else if let view = view as? PostMarkerAnnotationView {
            view.glyphTintColor = mistUIColor() //this is needed bc for some reason the glyph tint color turns grey even with the mist-heart-pink icon
            view.markerTintColor = mistSecondaryUIColor()
            
            slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset,
                      long: view.annotation!.coordinate.longitude,
                      incrementalZoom: false,
                      withDuration: cameraAnimationDuration,
                      completion: { _ in })
            loadPostViewFor(postAnnotationView: view,
                            withDelay: cameraAnimationDuration)
        }
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("did deselect")
        if let view = view as? PostMarkerAnnotationView {
            view.glyphTintColor = .white
            view.markerTintColor = mistUIColor()
        }
        
        if let postView: UIView = view.viewWithTag(POST_VIEW_TAG) {
            postView.fadeOut(duration: 0.5, delay: 0, completion: { Bool in
                postView.isHidden = true
                postView.removeFromSuperview()
                mapView.isScrollEnabled = true
                mapView.isZoomEnabled = true
            })
        }
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
    
    //MARK: - View Rendering
    
    func loadPostViewFor(postAnnotationView: PostMarkerAnnotationView,
                         withDelay delay: Double) {
        let cell = Bundle.main.loadNibNamed(Constants.SBID.Cell.Post, owner: self, options: nil)?[0] as! PostCell
        if let postAnnotation = postAnnotationView.annotation as? PostAnnotation {
            cell.configurePostCell(post: postAnnotation.post, parent: self, bubbleArrowPosition: .bottom)
        }
        let postView: UIView? = cell.contentView

        // Or, alternatively, instead of extracting from the PostCell.xib,, extract post from PostView.xib
    //        let postViewFromViewNib = Bundle.main.loadNibNamed(Constants.SBID.View.Post, owner: self, options: nil)?[0] as? PostView
        
        if let newPostView = postView {
            newPostView.tag = POST_VIEW_TAG
            newPostView.tintColor = .black
            newPostView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints
            postAnnotationView.addSubview(newPostView)
            NSLayoutConstraint.activate([
                newPostView.bottomAnchor.constraint(equalTo: postAnnotationView.bottomAnchor, constant: -70),
                newPostView.widthAnchor.constraint(equalTo: mapView.widthAnchor, constant: 0),
                newPostView.heightAnchor.constraint(lessThanOrEqualTo: mapView.heightAnchor, multiplier: 0.60, constant: 0),
                newPostView.centerXAnchor.constraint(equalTo: postAnnotationView.centerXAnchor, constant: 0),
            ])
            newPostView.alpha = 0
            newPostView.isHidden = true
            newPostView.fadeIn(duration: 0.2, delay: delay-0.15)
        }
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


//MARK: - ExploreViewController
    
extension ExploreMapViewController {
    
    // MARK: - User Interaction
    
    @IBAction func searchButtonDidPressed(_ sender: UIBarButtonItem) {
        dismissPost()
        present(mySearchController, animated: true)
        filterMapModalVC?.toggleSheetSizeTo(sheetSize: "zil") //eventually replace this with "dismissFilter()" when completion handler is added
        filterMapModalVC?.dismiss(animated: false)
    }
    
    //TODO: add custom animations
    //https://stackoverflow.com/questions/51675063/how-to-present-view-controller-from-left-to-right-in-ios
    //https://github.com/HeroTransitions/Hero
    @IBAction func myProfileButtonDidTapped(_ sender: UIBarButtonItem) {
        dismissPost()
        let myAccountNavigation = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation)
        myAccountNavigation.modalPresentationStyle = .fullScreen
        filterMapModalVC?.dismiss(animated: false) //same as above^
        filterMapModalVC?.toggleSheetSizeTo(sheetSize: "zil") //makes the transition more seamless
        self.navigationController?.present(myAccountNavigation, animated: true, completion: nil)
    }
}

extension ExploreMapViewController: UISearchControllerDelegate {
    func setupSearchBar() {
        //resultsTableViewController
        resultsTableController =
        self.storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.LiveResults) as? LiveResultsTableViewController
        resultsTableController.tableView.delegate = self // This view controller is interested in table view row selections.
        resultsTableController.tableView.contentInsetAdjustmentBehavior = .automatic //removes strange whitespace https://stackoverflow.com/questions/1703023/is-it-possible-to-access-a-uitableviews-scrollview-in-code-from-a-nib
        
        resultsTableController.resultsLabelView.isHidden = true

        //searchController
        mySearchController = UISearchController(searchResultsController: resultsTableController)
        mySearchController.delegate = self
        mySearchController.searchResultsUpdater = self
        mySearchController.showsSearchResultsController = true //means that we don't need "map cover view" anymore
        
        //https://stackoverflow.com/questions/68106036/presenting-uisearchcontroller-programmatically
        //this creates unideal ui, but im not going to spend more time trying to fix this right now.
        //mySearchController.hidesNavigationBarDuringPresentation = false //true by default

        //todo later: TWO WAYS OF MAKING SEARCH BAR PRETTY
        //definePresentationContext = false (plus) self.present(searchcontroller)
        //definePresentationContext = true (plus) navigationController?.present(searchController)
        definesPresentationContext = true //false by default
        
        //searchBar
        mySearchController.searchBar.tintColor = .darkGray
        mySearchController.searchBar.delegate = self // Monitor when the search button is tapped.
        mySearchController.searchBar.autocapitalizationType = .none
        mySearchController.searchBar.searchBarStyle = .prominent //when setting to .minimal, the background disappears and you can see nav bar underneath. if using .minimal, add a background color to searchBar to fix this.
        mySearchController.searchBar.placeholder = "Search"
    }
    
    func presentSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
//        navigationController?.hideHairline()
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        navigationItem.searchController = searchController
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        print("will dismiss sc")
//        navigationController?.restoreHairline()
        navigationItem.searchController = .none
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
}

    // MARK: - UISearchBarDelegate

extension ExploreMapViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = mySearchController.searchBar.text else { return }

        switch resultsTableController.selectedScope {
            case 0:
                //TODO: idea: what if you present a new navigation controller , with its root view controller as the newQueryFeedViewController. will this fix aesthetic issues?
            let newQueryFeedViewController = ResultsFeedViewController.resultsFeedViewController(feedType: .query, feedValue: text)
                navigationController?.pushViewController(newQueryFeedViewController, animated: true)
            case 1:
                break
            default: break
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        resultsTableController.selectedScope = selectedScope
        resultsTableController.liveResults = []
        updateSearchResults(for: mySearchController)
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
}

    // MARK: - UITableViewDelegate

extension ExploreMapViewController: UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch resultsTableController.selectedScope {
        case 0:
            let word = resultsTableController.liveResults[indexPath.row] as! Word
            let newQueryFeedViewController = ResultsFeedViewController.resultsFeedViewController(feedType: .query, feedValue: word.text)
            navigationController?.pushViewController(newQueryFeedViewController, animated: true)
        case 1:
            break
            //let profile = liveResults[indexPath.row] as! Profile
            //TODO: navigate to profile page
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension ExploreMapViewController: UISearchResultsUpdating {
    
    //Update the filtered array based on the search text.
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        guard !text.isEmpty else {
            //User might have typed a word into the searchbar, but then deleted it. so lets reset the live results.
            //We dont reset live results normally because we want the previous search results to stay visible
            //until the new db call returns.
            resultsTableController.liveResults = []
            resultsTableController.tableView.reloadData()
            resultsTableController.resultsLabelView.isHidden = true
            return
        }
        resultsTableController.resultsLabelView.isHidden = false
        
        if let resultsController = searchController.searchResultsController as? LiveResultsTableViewController {
            Task {
                do {
                    resultsTableController.resultsLabel.text = "Searching..."
                    switch resultsController.selectedScope {
                    case 0:
                        resultsController.liveResults = try await WordAPI.fetchWords(text: text)
                    case 1:
                        print("doing a profile search with: " + text)
                        resultsController.liveResults = try await UserAPI.fetchUsersByText(containing: text)
                    default: break
                    }
                    resultsController.tableView.reloadData()
                    resultsController.resultsLabel.text = resultsController.liveResults.isEmpty ? "No items found": String(format:"Items found: %d",resultsController.liveResults.count)
                } catch {
                    print(error)
                }
            }
        }
    }
    
}

