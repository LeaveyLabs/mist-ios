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
        searchSuggestionsVC.tableView.contentInsetAdjustmentBehavior = .automatic //necessary for setting bottom insets properly
        setupTableViewSectionShadows()

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
    
    func setupTableViewSectionShadows() {
        //apply shadow only to the tableView's sections
        let tableView = searchSuggestionsVC.tableView!
        tableView.backgroundColor = .clear
        tableView.subviews.forEach { subview in
            subview.applyMediumShadow()
        }
        
        //setup white map cover to compensite for tableview's clear background. make it much longer than the suggestion results tableview would ever be
        let tableViewExtraBackgroundView = UIView.init(frame: .init(x: view.frame.minX,
                                                     y: view.frame.minY - 500,
                                                     width: view.frame.width,
                                                     height: view.frame.height + 1000))
        tableViewExtraBackgroundView.backgroundColor = .systemGroupedBackground
        tableView.addSubview(tableViewExtraBackgroundView)
        tableView.sendSubviewToBack(tableViewExtraBackgroundView)
        
        //i couldnt get constraints to work for some reason
//        whiteMapCoverView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            whiteMapCoverView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 0),
//            whiteMapCoverView.rightAnchor.constraint(equalTo: tableView.rightAnchor),
//            whiteMapCoverView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: -1),
//            whiteMapCoverView.centerXAnchor.constraint(equalTo: tableView.leftAnchor),
//        ])
    }
}

// MARK: - SearchController Delegate

extension ExploreViewController: UISearchControllerDelegate {
    
    func presentSearchController(_ searchController: UISearchController) {
//        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        mySearchController.searchBar.placeholder = MapSearchResultType.randomPlaceholder()
        present(mySearchController, animated: true) {
            self.searchSuggestionsVC.tableView.contentInset.top -= self.view.safeAreaInsets.top - 20 //needed bc auto content inset adjustment behavior isn't reflecing safeareainsets for some reason
        }
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
//        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
//        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
//        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        searchBarButton.centerText()
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
//        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
}

    // MARK: - UISearchBarDelegate

extension ExploreViewController: UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchSuggestionsVC.startProvidingCompletions(for: MKCoordinateRegion(center: mapView.centerCoordinate, span: .init(latitudeDelta: minSpanDelta, longitudeDelta: minSpanDelta)))
        if searchBar == searchBarButton {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { //the duration of the uisearchcontroller animation
                self.resetCurrentFilteredSearch()
            }
            mySearchController.isActive = true //calls its delegate's presentSearchController
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
            postFilter.searchBy = .text
            searchBarButton.text = word.text
            reloadPosts() { [self] in
                centerMapAround(postAnnotations)
            }
        case .nearby:
            let suggestion = searchSuggestionsVC.completerResults![indexPath.row]
            postFilter.searchBy = .location
            searchBarButton.text = suggestion.title
            search(for: suggestion)
        }
        searchBarButton.searchTextField.leftView?.tintColor = cornerButtonGrey
        mySearchController.isActive = false
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let titleView = view as! UITableViewHeaderFooterView
        titleView.textLabel?.text =  titleView.textLabel?.text?.lowercased().capitalizeFirstLetter()
    }
    
}

// MARK: - CLLocationManagerDelegate

extension ExploreViewController {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemark, error) in
            guard error == nil else { return }
            //Here, you can do something on a successful user location update
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
        searchRequest.region = mapView.region //this is important
        searchRequest.resultTypes = [.address, .pointOfInterest]
        localSearch = MKLocalSearch(request: searchRequest)
        localSearch?.start { [self] (response, error) in
            if let error = error as? MKError {
                if error.errorCode == 4 {
                    CustomSwiftMessages.showInfo("No results were found.", "Please search again.", emoji: "😔")
                } else {
                    CustomSwiftMessages.displayError(error)
                }
                return
            }
            
            if let updatedRegion = response?.boundingRegion, var places = response?.mapItems {
                //We allow the search completer's searchRegion to be .world so that specific locations from one particular place can appear
                //However, for the "queryString" search option, where Apple provides the "Search Starbucks near here", because the region is so large, it will display Starbucks from reaaaally away too.
                //So in the case that places.count > 0 with the queryString search, we just to display the 5 places closest to the mapView's current region.center
                if places.count > 1 {
                    places = Array(places.sorted(by: { first, second in
                        mapView.centerCoordinate.distance(from: first.placemark.coordinate) < mapView.centerCoordinate.distance(from: second.placemark.coordinate)
                    }).prefix(5))
                    centerMapAround(places) //updates mapView.region
                } else {
                    mapView.region = updatedRegion
                }
                mapView.region.span.latitudeDelta = max(minSpanDelta, mapView.region.span.latitudeDelta)
                
                //Once mapView's region has been updated, we can call reloadPosts, which will load in the posts around that region
                reloadPosts() {
                    self.prepareToDismissSearchControllerForLocallySearchedMapView(itemsToDisplay: places)
                }
            }
        }
    }
    
    //input paramater: itemsToDispaly OR a bool indicating if showOne or showAll
    func prepareToDismissSearchControllerForLocallySearchedMapView(itemsToDisplay: [MKMapItem]) {
        removeExistingPlaceAnnotations()
        
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
