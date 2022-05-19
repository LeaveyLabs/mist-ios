//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import SwiftUI
import MapKit
import SwiftyAttributes

///reference for search controllers
///https://developer.apple.com/documentation/uikit/view_controllers/using_suggested_searches_with_a_search_controller
///https://developer.apple.com/documentation/uikit/view_controllers/displaying_searchable_content_by_using_a_search_controller

//TODO: add 2d/3d button. shift to 2d automatically after a certain height

class ExploreMapViewController: MapViewController {
    
    // MARK: - Properties
    @IBOutlet weak var mistTitle: UIView!
    @IBOutlet weak var filterButton: UIButton!
        
    // ExploreViewController
    var mySearchController: UISearchController!
    private var resultsTableController: LiveResultsTableViewController!
    var filterMapModalVC: FilterViewController?

    // PostsService
    var postsService: PostsService!
    var postFilter = PostFilter()

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        latitudeOffset = 0.0010
        navigationItem.titleView = mistTitle

        updateFilterButtonLabel()
        
        filterButton.layer.cornerRadius = 10
        applyShadowOnView(filterButton)
        
        setupSearchBar()
        setupPostsService()
        reloadPosts()
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
    
    //MARK: - User Interaction
    
    @IBAction func filterButtonDidTapped(_ sender: UIButton) {
        let filterVC = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Filter) as! FilterViewController
        filterVC.delegate = self
        filterVC.selectedFilter = postFilter
        filterVC.loadViewIfNeeded() //doesnt work without this function call
        filterMapModalVC = filterVC
        present(filterVC, animated: true)
    }
    
    //MARK: - Helpers
    
    func updateFilterButtonLabel() {
        var postTypeString = NSAttributedString(string: postFilter.postType.rawValue).withFont(UIFont(name: Constants.Font.Heavy, size: 24)!)
        if postFilter.postType == .Friends {
            postTypeString = NSAttributedString(string: "Friends'").withFont(UIFont(name: Constants.Font.Heavy, size: 24)!)
        }
        var middleString = NSAttributedString(string: " mists from ").withFont(UIFont(name: Constants.Font.Medium, size: 24)!)
        if postFilter.postType == .Matches {
            middleString = NSAttributedString(string: " from ").withFont(UIFont(name: Constants.Font.Medium, size: 24)!)
        }
        let postTimeframeString = NSAttributedString(string: getDateFromSlider(indexFromZeroToOne: postFilter.postTimeframe)).withFont(UIFont(name: Constants.Font.Heavy, size: 24)!)
        let newText: NSAttributedString = postTypeString + middleString + postTimeframeString
        filterButton.setAttributedTitle(newText, for: .normal)
    }
    
    
    //MARK: - Map
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        filterMapModalVC?.dismiss(animated: true)
        if view.annotation is MKUserLocation {
            mapView.deselectAnnotation(view.annotation, animated: false)
            mapView.userLocation.title = "Hey cutie"
        }
        else if let clusterAnnotation = view.annotation as? MKClusterAnnotation {
            mapView.deselectAnnotation(view.annotation, animated: false)
            if clusterAnnotation.isHotspot {
                var posts = [Post]()
                for annotation in clusterAnnotation.memberAnnotations {
                    if let annotation = annotation as? PostAnnotation {
                        posts.append(annotation.post)
                        
                    }
                }
                let newVC = ResultsFeedViewController.resultsFeedViewController(feedType: .hotspot, feedValue: clusterAnnotation.title!)
                newVC.posts = posts
                navigationController?.pushViewController(newVC, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in //wait 0.5 seconds
                    centerMapOn(lat: view.annotation!.coordinate.latitude, long: view.annotation!.coordinate.longitude)
                }
            } else {
                slowFlyTo(lat: view.annotation!.coordinate.latitude, long: view.annotation!.coordinate.longitude, incrementalZoom: true, completion: {_ in })
            }
        }
        else if let view = view as? PostMarkerAnnotationView {
            view.glyphTintColor = mistUIColor() //this is needed bc for some reason the glyph tint color turns grey even with the mist-heart-pink icon
            view.markerTintColor = mistSecondaryUIColor()
            
            slowFlyTo(lat: view.annotation!.coordinate.latitude + latitudeOffset, long: view.annotation!.coordinate.longitude, incrementalZoom: false, completion: {_ in })
            loadPostViewFor(postAnnotationView: view)
        }
    }

    func loadPostViewFor(postAnnotationView: PostMarkerAnnotationView) {
        let cell = Bundle.main.loadNibNamed(Constants.SBID.Cell.Post, owner: self, options: nil)?[0] as! PostCell
        if let postAnnotation = postAnnotationView.annotation as? PostAnnotation {
            cell.configurePostCell(post: postAnnotation.post, parent: self, bubbleArrowPosition: .bottom)
        }
        let postView: UIView? = cell.contentView

        // Or, alternatively, instead of extracting from the PostCell.xib,, extract post from PostView.xib
    //        let postViewFromViewNib = Bundle.main.loadNibNamed(Constants.SBID.View.Post, owner: self, options: nil)?[0] as? PostView
        
        if let newPostView = postView {
            newPostView.tag = 999
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
            newPostView.fadeIn(duration: 0.2, delay: cameraAnimationDuration-0.15)
        }
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let view = view as? PostMarkerAnnotationView {
            view.glyphTintColor = .white
            view.markerTintColor = mistUIColor()
        }
        
        if let postView: UIView = view.viewWithTag(999) {
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
        if !cameraIsMoving {
//            print("trying to dismiss filter")
            filterMapModalVC?.dismiss(animated: true)
        }
    }
    
    // TF does this do?
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
    
    func reloadPosts() {
        Task {
            do {
                let loadedPosts = try await postsService.newPostsNearby(latitude: Constants.Coordinates.USC.latitude, longitude: Constants.Coordinates.USC.longitude)
                
                //Can this be handled by postsService instead?
                //turn the first 10000..?? lol posts returned into PostAnnotations so they will be added to the map
                displayedAnnotations = []
                for index in 0...min(10000, loadedPosts.count-1) {
                    let postAnnotation = PostAnnotation(withPost: loadedPosts[index])
                    displayedAnnotations.append(postAnnotation)
                }
                
            } catch {
                print(error)
            }
        }
    }
    
}

extension ExploreMapViewController: FilterDelegate {
    
    func reloadPostsAfterFilterUpdate(newPostFilter: PostFilter) {
        
        //Should eventually remove one of these two and have filter just saved in one location
        postsService.setFilter(to: newPostFilter)
        postFilter = newPostFilter
        
        updateFilterButtonLabel()
        reloadPosts()
    }
    
}




//MARK: - ExploreViewController
    
extension ExploreMapViewController {
    
    // MARK: - User Interaction
    
    @IBAction func searchButtonDidPressed(_ sender: UIBarButtonItem) {
        present(mySearchController, animated: true)
    }
    
    //TODO: add custom animations
    //https://stackoverflow.com/questions/51675063/how-to-present-view-controller-from-left-to-right-in-ios
    //https://github.com/HeroTransitions/Hero
    @IBAction func myProfileButtonDidTapped(_ sender: UIBarButtonItem) {
        let myAccountNavigation = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation)
        myAccountNavigation.modalPresentationStyle = .fullScreen
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

    // MARK: - UISearchControllerDelegate

extension ExploreMapViewController {
    
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
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
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
                        resultsController.liveResults = try await ProfileAPI.fetchProfilesByText(text: text)
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

