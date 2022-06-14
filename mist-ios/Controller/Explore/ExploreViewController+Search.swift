//
//  ExploreMapViewController+Search.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/05.
//

import Foundation
import CoreLocation
import MapKit
    
//MARK: - Search

//MARK: - Search Setup

extension ExploreViewController {
    
    func setupSearchButton() {
        searchButton.becomeRound()
        applyShadowOnView(searchButton)
        searchButton.clipsToBounds = false //for shadow to take effect
    }
    
    func setupSearchBar() {
        //self
        definesPresentationContext = true //necessary so that pushes go to the next controller

        //resultsTableViewController
        searchSuggestionsVC = self.storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.SearchSuggestions) as? SearchSuggestionsTableViewController
        searchSuggestionsVC.tableView.delegate = self
        searchSuggestionsVC.tableView.contentInsetAdjustmentBehavior = .automatic //necessary for setting bottom insets properly
        
        //searchController
        mySearchController = UISearchController(searchResultsController: searchSuggestionsVC)
        mySearchController.delegate = self
        mySearchController.searchResultsUpdater = searchSuggestionsVC // requires conformance to UISearchResultsUpdating extension
        mySearchController.showsSearchResultsController = true //so white background is always visible
        
        //searchBar
        mySearchController.searchBar.delegate = self // Monitor when the search button is tapped.
        mySearchController.searchBar.scopeButtonTitles = []
        MapSearchScope.allCases.forEach { mapSearchScope in
            mySearchController.searchBar.scopeButtonTitles?.append(mapSearchScope.displayName)
        }
        
        mySearchController.searchBar.tintColor = .darkGray
        mySearchController.searchBar.autocapitalizationType = .none
        mySearchController.searchBar.searchBarStyle = .prominent //when setting to .minimal, the background disappears and you can see nav bar underneath. if using .minimal, add a background color to searchBar to fix this.
    }
}

// MARK: - Search User Interaction

extension ExploreViewController {
        
    @IBAction func searchButtonDidPressed(_ sender: UIBarButtonItem) {
        mySearchController.isActive = true //calls its delegate's presentSearchController
        filterMapModalVC?.toggleSheetSizeTo(sheetSize: "zil") //eventually replace this with "dismissFilter()" when completion handler is added
        filterMapModalVC?.dismiss(animated: false)
    }
    
    @IBAction func myProfileButtonDidTapped(_ sender: UIBarButtonItem) {
        dismissPost()
        let myAccountNavigation = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation)
        myAccountNavigation.modalPresentationStyle = .fullScreen
        filterMapModalVC?.dismiss(animated: false) //same as above^
        filterMapModalVC?.toggleSheetSizeTo(sheetSize: "zil") //makes the transition more seamless
        self.navigationController?.present(myAccountNavigation, animated: true, completion: nil)
    }
}

// MARK: - SearchController Delegate

extension ExploreViewController: UISearchControllerDelegate {
    
    func presentSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        mySearchController.searchBar.placeholder = searchSuggestionsVC.selectedScope.randomPlaceholder
        present(mySearchController, animated: true) {
            self.mySearchController.searchBar.showsScopeBar = true //needed to prevent weird animation
            self.searchSuggestionsVC.tableView.contentInset.top -= self.view.safeAreaInsets.top - 10 //needed bc auto content inset adjustment behavior isn't reflecing safeareainsets for some reason
        }
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        mySearchController.searchBar.setShowsScope(false, animated: false) //needed to prevent weird animation
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
}

    // MARK: - UISearchBarDelegate

extension ExploreViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = mySearchController.searchBar.text else { return }

        switch searchSuggestionsVC.selectedScope {
        case .locatedAt:
            search(for: searchBar.text) //Must be called before deactivating mySearchController since searchBar is a property of it
            mySearchController.isActive = false
        case .containing:
            let newQueryFeedViewController = SearchResultsTableViewController.resultsFeedViewController(feedType: .query, feedValue: text)
            navigationController?.pushViewController(newQueryFeedViewController, animated: true)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let newSelectedScope = MapSearchScope(rawValue: selectedScope) else { return }
        mySearchController.searchBar.placeholder = searchSuggestionsVC.selectedScope.randomPlaceholder
        searchSuggestionsVC.selectedScope = newSelectedScope
        searchSuggestionsVC.liveResults = []
        searchSuggestionsVC.completerResults = []
        searchSuggestionsVC.tableView.reloadData() //to get rid of the data from the previous scope
        searchSuggestionsVC.updateSearchResults(for: mySearchController)
    }
}

    // MARK: - UITableViewDelegate

extension ExploreViewController: UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        switch searchSuggestionsVC.selectedScope {
        case .locatedAt:
            if let suggestion = searchSuggestionsVC.completerResults?[indexPath.row] {
                mySearchController.isActive = false
                search(for: suggestion)
            }
        case .containing:
            let word = searchSuggestionsVC.liveResults[indexPath.row] as! Word
            let newQueryFeedViewController = SearchResultsTableViewController.resultsFeedViewController(feedType: .query, feedValue: word.text)
            navigationController?.pushViewController(newQueryFeedViewController, animated: true)
        }
    }
}

// MARK: - CLLocationManagerDelegate updating location for Map Search

extension ExploreViewController {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("locationmanager didUpdateLocations")
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemark, error) in
            guard error == nil else { return }
            
            self.boundingRegion = MKCoordinateRegion(center: location.coordinate,
                                                     latitudinalMeters: 12_000,
                                                     longitudinalMeters: 12_000)
//            self.currentPlacemark = placemark?.first
//            self.searchSuggestionsVC.updatePlacemark(self.currentPlacemark, boundingRegion: self.boundingRegion)
        }
    }
}

// MARK: - Map Search

extension ExploreViewController {
    
    
    /// - Parameter suggestedCompletion: A search completion provided by `MKLocalSearchCompleter` when tapping on a search completion table row
    private func search(for suggestedCompletion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: suggestedCompletion)
        search(using: searchRequest)
    }
    
    /// - Parameter queryString: A search string from the text the user entered into `UISearchBar`
    private func search(for queryString: String?) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = queryString
        search(using: searchRequest)
    }
    
    /// - Tag: SearchRequest
    private func search(using searchRequest: MKLocalSearch.Request) {
        //center the search around where the user is currently looking at
        boundingRegion = MKCoordinateRegion(center: mapView.centerCoordinate,
                                            latitudinalMeters: 6_000,
                                            longitudinalMeters: 6_000)
        searchRequest.region = boundingRegion //even though the user can see suggestions from all over the world, when they press search button, we want to confine the search area to results somewhat nearby them so they don't get super disoriented
        
        searchRequest.resultTypes = [.address, .pointOfInterest]
        
        localSearch = MKLocalSearch(request: searchRequest)
        localSearch?.start { [unowned self] (response, error) in
            if let error = error as? MKError {
                if error.errorCode == 4 {
                    CustomSwiftMessages.showInfo("No results were found.", "Please search again.", emoji: "😔")
                } else {
                    CustomSwiftMessages.showError(errorDescription: "Something went wrong.")
                }
                return
            }
            
            if let updatedRegion = response?.boundingRegion {
                self.boundingRegion = updatedRegion
            }
            
            if let places = response?.mapItems, places.count > 0 {
                prepareToDismissSearchControllerForLocallySearchedMapView(itemsToDisplay: places)
            }
        }
    }
    
    //input paramater: itemsToDispaly OR a bool indicating if showOne or showAll
    func prepareToDismissSearchControllerForLocallySearchedMapView(itemsToDisplay: [MKMapItem]) {
        // Update map's camera
        mapView.region = boundingRegion
        
        // Remove previous search annotations
        mapView.annotations.forEach { annotation in
            if let placeAnnotation = annotation as? PlaceAnnotation {
                mapView.removeAnnotation(placeAnnotation)
            }
        }
        
        // Turn the array of MKMapItem objects into an annotation with a title and URL that can be shown on the map.
        let annotations = itemsToDisplay.compactMap { (mapItem) -> PlaceAnnotation? in
            guard let coordinate = mapItem.placemark.location?.coordinate else { return nil }
            
            let annotation = PlaceAnnotation(coordinate: coordinate)
            annotation.title = mapItem.name
            annotation.category = mapItem.pointOfInterestCategory
            
            return annotation
        }
        mapView.addAnnotations(annotations)
    }
    
}
