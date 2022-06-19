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
                searchSuggestionsVC.startProvidingCompletions(for: MKCoordinateRegion(center: mapView.centerCoordinate, span: .init(latitudeDelta: minSpanDelta, longitudeDelta: minSpanDelta)))
                resetCurrentFilteredSearch() //TODO: change this. if they press search and then cancel, we dont want to relocate them to a new part of the world
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
        tableView.deselectRow(at: indexPath, animated: false)
        let resultType = MapSearchResultType.init(rawValue: indexPath.section)!
        
        switch resultType {
        case .containing:
            let word = searchSuggestionsVC.wordResults[indexPath.row]
            searchBarButton.text = word.text
            postFilter.searchBy = .text
            reloadPosts(withType: .newSearch)
        case .nearby:
            let suggestion = searchSuggestionsVC.completerResults[indexPath.row]
            searchBarButton.text = suggestion.title
            postFilter.searchBy = .location
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
    private func search(for queryString: String?) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = queryString
        search(using: searchRequest)
    }
    
    /// - Tag: SearchRequest
    private func search(using searchRequest: MKLocalSearch.Request) {
        searchRequest.region = mapView.region //this is important. center the search around the current visible region
        searchRequest.resultTypes = [.address, .pointOfInterest]
        localSearch = MKLocalSearch(request: searchRequest)
        localSearch?.start { [self] (response, error) in
            if let error = error as? MKError {
                CustomSwiftMessages.displayError(error)
                return
            }
            
            guard let places = response?.mapItems else { return } //if we didn't get an error 4, this should be OK
            turnPlacesIntoAnnotations(places)
            reloadPosts(withType: .newSearch)
        }
    }
    
}
