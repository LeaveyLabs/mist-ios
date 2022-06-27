//
//  ExploreMapViewController+Search.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/05.
//

import Foundation
import CoreLocation
import MapKit
    
//MARK: - Search Setup

let cornerButtonGrey = UIColor.black.withAlphaComponent(0.7)

extension ExploreViewController {
    
    func setupSearchBarButton() {
        searchBarButton.delegate = self
        searchBarButton.setImage(UIImage(), for: .clear, state: .normal)
        searchBarButton.searchTextField.leftView?.tintColor = .secondaryLabel
        searchBarButton.searchTextField.textColor = cornerButtonGrey
    }
    
    func setupSearchBar() {
        //self
        definesPresentationContext = true //necessary so that pushes go to the next controller

        //resultsTableViewController
        searchSuggestionsVC = self.storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.SearchSuggestions) as? SearchSuggestionsTableViewController
        searchSuggestionsVC.tableView.delegate = self
        searchSuggestionsVC.tableView.setupTableViewSectionShadows(behindView: view)

        //searchController
        mySearchController = UISearchController(searchResultsController: searchSuggestionsVC)
        mySearchController.delegate = self
        mySearchController.searchResultsUpdater = searchSuggestionsVC // requires conformance to UISearchResultsUpdating extension
        mySearchController.showsSearchResultsController = true //so white background is always visible
        
        //searchBar
        mySearchController.searchBar.delegate = self // Monitor when the search button is tapped.
        mySearchController.searchBar.tintColor = cornerButtonGrey
        mySearchController.searchBar.searchTextField.tintColor = mistUIColor()
        mySearchController.searchBar.autocapitalizationType = .none
        mySearchController.searchBar.searchBarStyle = .prominent //when setting to .minimal, the background disappears and you can see nav bar underneath. if using .minimal, add a background color to searchBar to fix this.
    }
    
}

// MARK: - SearchController Delegate

extension ExploreViewController: UISearchControllerDelegate {
    
    func willDismissSearchController(_ searchController: UISearchController) {
//        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        searchBarButton.centerText()
    }
    
}

    // MARK: - UISearchBarDelegate

extension ExploreViewController: UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if searchBar == searchBarButton {
            if mySearchController.isActive || mySearchController.isBeingPresented { return false }
            mySearchController.searchBar.placeholder = MapSearchResultType.randomPlaceholder()
            present(mySearchController, animated: true) { [self] in
                searchSuggestionsVC.startProvidingCompletions(for: MKCoordinateRegion(center: mapView.region.center, latitudinalMeters: 100, longitudinalMeters: 100))
                resetCurrentFilter() //TODO: change this. if they press search and then cancel, we dont want to relocate them to a new part of the world
            }
            return false
        }
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        mySearchController.searchBar.resignFirstResponder()
    }
    
}

    // MARK: - UITableViewDelegate

extension ExploreViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == feed { return }
        tableView.deselectRow(at: indexPath, animated: false)
        let resultType = MapSearchResultType.init(rawValue: indexPath.section)!
        
        switch resultType {
        case .containing:
            let word = searchSuggestionsVC.wordResults[indexPath.row]
            searchBarButton.text = word.text
            PostService.singleton.updateFilter(newText: word.text)
            PostService.singleton.updateFilter(newSearchBy: .text)
            reloadPosts(withType: .newSearch)
        case .nearby:
            let suggestion = searchSuggestionsVC.completerResults[indexPath.row]
            searchBarButton.text = suggestion.title
            PostService.singleton.updateFilter(newSearchBy: .location)
            search(for: suggestion) //first gets places from Apple, then calls reloadPosts()
        }
        searchBarButton.searchTextField.leftView?.tintColor = cornerButtonGrey
        mySearchController.isActive = false
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let titleView = view as? UITableViewHeaderFooterView else { return } //disregard the feed's headerView
        titleView.textLabel?.text =  titleView.textLabel?.text?.lowercased().capitalizeFirstLetter()
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
    //Not in use right now. We only let the user search via suggestions. If we let the user search for locations by typing in "star" and pressing search button, then we would need to uncomment this
//    private func search(for queryString: String?) {
//        let searchRequest = MKLocalSearch.Request()
//        searchRequest.naturalLanguageQuery = queryString
//        search(using: searchRequest)
//    }
    
    /// - Tag: SearchRequest
    private func search(using searchRequest: MKLocalSearch.Request) {
        searchRequest.region = MKCoordinateRegion(center: mapView.region.center, latitudinalMeters: 100, longitudinalMeters: 100) //setting a span that's smaller or larger seems to increase the frequency that apple will reset the search region to your current location. 10000 seems to be a good middle ground
        searchRequest.resultTypes = [.address, .pointOfInterest]
        let localSearch = MKLocalSearch(request: searchRequest)
        Task {
            do {
                let response = try await localSearch.start()
                if didAppleOverrideLocalSearchRegion(response.boundingRegion) {
                    CustomSwiftMessages.showInfo("No results found.", "Try adjusting the map and search again.", emoji: "🧐")
                } else {
                    appleregion = response.boundingRegion
                    turnPlacesIntoAnnotations(response.mapItems)
                    PostService.singleton.updateFilter(newRegion: getRegionCenteredAround(placeAnnotations)!)
                    reloadPosts(withType: .newSearch)
                }
            } catch {
                if let error = error as? MKError {
                    CustomSwiftMessages.displayError(error)
                    return
                }
            }
        }
    }
    
    //if the map wasnt originally near the user's location, but then the center of the response is close to the user's location, apple overrided the search. in that case, don't display anything and tell the user to search again
    func didAppleOverrideLocalSearchRegion(_ responseRegion: MKCoordinateRegion) -> Bool {
        if let userLocation = locationManager.location {        print(mapView.region.center.distance(from: userLocation.coordinate))
            print(responseRegion.center.distance(from: userLocation.coordinate))
            if mapView.region.center.distance(from: userLocation.coordinate) > 10000 && responseRegion.center.distance(from: userLocation.coordinate) < 2500 {
                return true
            }
        }
        return false
    }
    
}
