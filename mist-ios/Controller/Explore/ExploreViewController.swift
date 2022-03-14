//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import SwiftUI
import MapKit

///reference
///https://developer.apple.com/documentation/uikit/view_controllers/using_suggested_searches_with_a_search_controller
///https://developer.apple.com/documentation/uikit/view_controllers/displaying_searchable_content_by_using_a_search_controller

class ExploreViewController: UIViewController, UITableViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var mistTitle: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapCoverView: UIView!

    /// Search controller to help us with filtering items in the table view.
    var searchController: UISearchController!
    
    /// Search results table view.
    private var resultsTableController: LiveResultsTableViewController!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let coordinate = CLLocationCoordinate2D(latitude: 34.0204, longitude: -118.2861)
        let region = mapView.regionThatFits(MKCoordinateRegion(center: coordinate, latitudinalMeters: 1200, longitudinalMeters: 1200))
        mapView.setRegion(region, animated: true)
        mapView.pointOfInterestFilter = .excludingAll
        view.sendSubviewToBack(mapCoverView)
        
        let annotation = MKPointAnnotation()
        annotation.title = "Omg this guy named kevin in my history class"
        annotation.subtitle = "Ok so we met in the dining hall and then.."
        annotation.coordinate = CLLocationCoordinate2D(latitude: 34.0204, longitude: -118.2861)
        mapView.addAnnotation(annotation)
    
        resultsTableController =
        self.storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.LiveResults) as? LiveResultsTableViewController
        // This view controller is interested in table view row selections.
        resultsTableController.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.scopeButtonTitles = ["Posts", "Users"]
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self // Monitor when the search button is tapped.
    
        //navigationController?.navigationBar.backgroundColor = .green
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.titleView = mistTitle
        navigationItem.hidesSearchBarWhenScrolling = false
        
        /** Search presents a view controller by applying normal view controller presentation semantics.
            This means that the presentation moves up the view controller hierarchy until it finds the root
            view controller or one that defines a presentation context.
        */
        
        /** Specify that this view controller determines how the search controller is presented.
            The search controller should be presented modally and match the physical size of this view controller.
        */
        definesPresentationContext = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //present(searchController, animated: true)
        //Here you can optionally add "restore" functionality in appdelegate for this code below to work.
        //Reference Apple's example xcode project for more details
    }
    
    // MARK: - IBActions
    
    @IBAction func outerViewDidTapped(_ sender: UITapGestureRecognizer) {
        print("outer view tapped")
        searchController.dismiss(animated: true)
    }

}


// MARK: - UISearchBarDelegate

extension ExploreViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchController.searchBar.text else { return }
        
        switch resultsTableController.selectedScope {
            case 0:
                let newQueryFeedViewController = ResultsFeedViewController.resultsFeedViewControllerForQuery(text)
                navigationController?.pushViewController(newQueryFeedViewController, animated: true)
                searchBar.resignFirstResponder()
            case 1:
                break
            default: break
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        updateSearchResults(for: searchController)
        resultsTableController.selectedScope = selectedScope
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        view.bringSubviewToFront(mapCoverView)
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        view.sendSubviewToBack(mapCoverView)
        //TODO: add a modal transition for mapCoverView
        return true
    }
    
}

// MARK: - UISearchControllerDelegate

// Use these delegate functions for additional control over the search controller.

extension ExploreViewController: UISearchControllerDelegate {
    
    func presentSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        updateSearchResults(for: searchController)
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
}

extension ExploreViewController: UISearchResultsUpdating {
    
    //Update the filtered array based on the search text.
    func updateSearchResults(for searchController: UISearchController) {
        
        return
        
        // Handle the scoping.
        let selectedScopeButtonIndex = searchController.searchBar.selectedScopeButtonIndex
        switch selectedScopeButtonIndex {
        case 0:
            break
        case 1:
            break
        default: break
        }
        
        //ensure there is text within the search bar
        guard let text = searchController.searchBar.text else {
            //? what to do here
        }
        print("text: " + text)
        // Apply the database results to the search results table.
        if let resultsController = searchController.searchResultsController as? LiveResultsTableViewController {
            Task {
                do {
                    resultsController.postResults = try await PostAPI.fetchPosts(text: text)
                    resultsController.tableView.reloadData()
                    resultsController.resultsLabel.text = resultsController.postResults.isEmpty ?
                        "No items found":
                        String(format:"Items found: %d",resultsController.postResults.count)
                    print("explore view content loaded")
                } catch {
                    print(error)
                }
            }
        }
    }
    
}

