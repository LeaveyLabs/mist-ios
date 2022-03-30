//
//  ExploreViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import SwiftUI
import MapKit

///reference for search controllers
///https://developer.apple.com/documentation/uikit/view_controllers/using_suggested_searches_with_a_search_controller
///https://developer.apple.com/documentation/uikit/view_controllers/displaying_searchable_content_by_using_a_search_controller

class ExploreViewController: MapViewController {
    
    // MARK: - Properties
    @IBOutlet weak var mistTitle: UIView!
    @IBOutlet weak var mapCoverView: UIView!
    @IBOutlet weak var myProfileButton: UIBarButtonItem!
    @IBOutlet weak var dmButton: UIBarButtonItem!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var createPostButton: UIBarButtonItem!
    
    /// Search controller to help us with filtering items in the table view.
    var searchController: UISearchController!
    
    /// Search results table view.
    private var resultsTableController: LiveResultsTableViewController!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.sendSubviewToBack(mapCoverView)
        loadExploreMapView()
                
        resultsTableController =
        self.storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.LiveResults) as? LiveResultsTableViewController
        // This view controller is interested in table view row selections.
        resultsTableController.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.isActive = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.scopeButtonTitles = ["Posts", "Users"]
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self // Monitor when the search button is tapped.
    
        searchController.hidesNavigationBarDuringPresentation = true
//        navigationItem.searchController = searchController
        navigationItem.titleView = mistTitle
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController.definesPresentationContext = true
        searchController.hidesNavigationBarDuringPresentation = false //dont make the existing navigation bar fly upwards
        
        /** Search presents a view controller by applying normal view controller presentation semantics.
            This means that the presentation moves up the view controller hierarchy until it finds the root
            view controller or one that defines a presentation context.
        */
        
        /** Specify that this view controller determines how the search controller is presented.
            The search controller should be presented modally and match the physical size of this view controller.
        */
        definesPresentationContext = true
    }
    
    //MARK: -Setup
    
    func loadExploreMapView() {
        Task {
            do {
                let nearbyPosts = try await PostAPI.fetchPosts(latitude: Constants.USC_LAT_LONG.latitude, longitude: Constants.USC_LAT_LONG.longitude)
                //turn the first ten posts returned into PostAnnotations and add them to the map
                for index in 0...min(9, nearbyPosts.count-1) {
                    let postAnnotation = BridgeAnnotation(withPost: nearbyPosts[index])
                    allAnnotations?.append(postAnnotation)
                }
                showAllAnnotations(self)
            } catch {
                print(error)
            }
        }
    }
    
    //MARK: -Navigation

    override func viewWillAppear(_ animated: Bool) {
        searchController.dismiss(animated: true)
//        print("can?")
//        print(self.definesPresentationContext)
//        print(searchController.canBecomeFirstResponder)
//        print(searchController.isFirstResponder)
//        print(searchController.isActive)
        //TODO: pull up search bar when returning to this VC after search via search button click
        //https://stackoverflow.com/questions/27951965/cannot-set-searchbar-as-firstresponder
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare for sender")
        self.definesPresentationContext = false
    }
    
    // MARK: - User Interaction
    
    @IBAction func outerViewDidTapped(_ sender: UITapGestureRecognizer) {
        print("outer view tapped")
        searchController.dismiss(animated: true)
    }
    
    @IBAction func searchButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.present(searchController, animated: true)
//        searchController.searchBar.becomeFirstResponder()
//        searchController.isActive = true
    }
    
    @IBAction func createPostButtonDidTapped(_ sender: UIBarButtonItem) {
        let vc = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewPostNavigation)
        vc.modalPresentationStyle = .fullScreen
       self.present(vc, animated: true, completion: nil)
    }
    
    //TODO: add custom animations
    //https://stackoverflow.com/questions/51675063/how-to-present-view-controller-from-left-to-right-in-ios
    //https://github.com/HeroTransitions/Hero
    @IBAction func myProfileButtonDidTapped(_ sender: UIBarButtonItem) {
        let myProfileVC = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.MyProfile) as! MyProfileViewController
        DispatchQueue.main.async { //make sure all UI updates are on the main thread.
//            self.navigationController?.view.layer.add(CATransition().segueFromLeft(), forKey: nil)
            self.navigationController?.pushViewController(myProfileVC, animated: true)
        }
    }
    
    
}

//MARK: -Map

extension ExploreViewController {
    
    func mapAnnotationDidTouched(_ sender: UIButton) {
        let mapModalVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.SortBy) as! SortByViewController
        if let sheet = mapModalVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersGrabberVisible = true
            sheet.largestUndimmedDetentIdentifier = .medium
        }
        present(mapModalVC, animated: true, completion: nil)
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
            case 1:
                break
            default: break
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        resultsTableController.selectedScope = selectedScope
        resultsTableController.liveResults = []
        updateSearchResults(for: searchController)
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

    // MARK: - UITableViewDelegate

extension ExploreViewController: UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch resultsTableController.selectedScope {
        case 0:
            let word = resultsTableController.liveResults[indexPath.row] as! Word
            let newQueryFeedViewController = ResultsFeedViewController.resultsFeedViewControllerForQuery(word.text)
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

// Use these delegate functions for additional control over the search controller.

extension ExploreViewController: UISearchControllerDelegate {
    
    func presentSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        navigationController?.hideHairline()
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        navigationController?.restoreHairline()
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
}

extension ExploreViewController: UISearchResultsUpdating {
    
    //Update the filtered array based on the search text.
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        guard !text.isEmpty else {
            //User might have typed a word into the searchbar, but then deleted it. so lets reset the live results.
            //We dont reset live results normally because we want the previous search results to stay visible
            //until the new db call returns.
            resultsTableController.liveResults = []
            resultsTableController.tableView.reloadData()
            return
        }
        
        if let resultsController = searchController.searchResultsController as? LiveResultsTableViewController {
            Task {
                do {
                    resultsTableController.resultsLabel.text = "Searching..."
                    switch resultsController.selectedScope {
                    case 0:
                        resultsController.liveResults = try await WordAPI.fetchWords(text: text)
                    case 1:
                        print("doing a profile search with: " + text)
                        resultsController.liveResults = try await ProfileAPI.fetchProfiles(text: text)
                    default: break
                    }
                    resultsController.tableView.reloadData()
                    resultsController.resultsLabel.text = resultsController.liveResults.isEmpty ?
                        "No items found":
                        String(format:"Items found: %d",resultsController.liveResults.count)
                } catch {
                    print(error)
                }
            }
        }
    }
    
}

