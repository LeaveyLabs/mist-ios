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

class ExploreMapViewController: MapViewController {
    
    // MARK: - Properties
    @IBOutlet weak var mistTitle: UIView!
    @IBOutlet weak var dateSliderOuterView: UIView!
    @IBOutlet weak var dateSliderView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    
    //ExploreViewController
    var mySearchController: UISearchController!
    private var resultsTableController: LiveResultsTableViewController!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = mistTitle
        
        //ExploreViewController
        loadExploreMapView()
        setupSearchBar()
        setupDateSlider()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //TODO: pull up search bar when returning to this VC after search via search button click
        //https://stackoverflow.com/questions/27951965/cannot-set-searchbar-as-firstresponder
    }
    
    //MARK: -Setup
    
    func setupDateSlider() {
        dateSliderView.layer.cornerRadius = 10
        dateSliderOuterView.layer.cornerRadius = 10
        applyShadowOnView(dateSliderOuterView)
    }
    
    //MARK: -User Interaction
    
    @IBAction func sliderValueDidChanged(_ sender: UISlider) {
        dateLabel.text = getDateFromSlider(indexFromOneToSeven: sender.value)
    }
    
    
    //MARK: -Map
    
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
    
}








//MARK: --------------ExploreViewController
    
extension ExploreMapViewController {
    
    // MARK: - User Interaction
    
    @IBAction func searchButtonDidPressed(_ sender: UIBarButtonItem) {
        present(mySearchController, animated: true)
    }
    
    //TODO: add custom animations
    //https://stackoverflow.com/questions/51675063/how-to-present-view-controller-from-left-to-right-in-ios
    //https://github.com/HeroTransitions/Hero
    @IBAction func myProfileButtonDidTapped(_ sender: UIBarButtonItem) {
        let myProfileVC = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.MyProfile) as! MyProfileViewController
//            self.navigationController?.view.layer.add(CATransition().segueFromLeft(), forKey: nil)
            self.navigationController?.pushViewController(myProfileVC, animated: true)
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
                        resultsController.liveResults = try await ProfileAPI.fetchProfiles(text: text)
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

