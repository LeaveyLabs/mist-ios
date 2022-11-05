//
//  ExploreViewController+Search.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/12/22.
//

import Foundation
import CoreLocation
import MapKit
    
//MARK: - Search Setup

let cornerButtonGrey = UIColor.black.withAlphaComponent(0.7)

extension MistCollectionViewController {
    
    func setupSearchBar() {
        //self
        definesPresentationContext = true //necessary so that pushes go to the next controller

        //resultsTableViewController
        searchSuggestionsVC = self.storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.SearchSuggestions) as? SearchSuggestionsTableViewController
        searchSuggestionsVC.tableView.delegate = self
        searchSuggestionsVC.tableView.setupTableViewSectionShadows(behindView: view, withBGColor: Constants.Color.offWhite)
        searchSuggestionsVC.isFragmentSearchEnabled = true
        
        //searchController
        mySearchController = UISearchController(searchResultsController: searchSuggestionsVC)
        mySearchController.delegate = self
        mySearchController.searchResultsUpdater = searchSuggestionsVC // requires conformance to UISearchResultsUpdating extension
        mySearchController.showsSearchResultsController = true //so white background is always visible
        
        //searchBar
        mySearchController.searchBar.enablesReturnKeyAutomatically = false
        mySearchController.searchBar.setValue("cancel", forKey: "cancelButtonText")
        mySearchController.searchBar.delegate = self // Monitor when the search button is tapped.
        mySearchController.searchBar.tintColor = Constants.Color.mistBlack
        mySearchController.searchBar.searchTextField.tintColor = Constants.Color.mistLilac
        mySearchController.searchBar.autocapitalizationType = .none
        mySearchController.searchBar.searchBarStyle = .prominent //when setting to .minimal, the background disappears and you can see nav bar underneath. if using .minimal, add a background color to searchBar to fix this.
        mySearchController.searchBar.searchTextField.font = UIFont(name: Constants.Font.Roman, size: 18)
    }
    
}

// MARK: - SearchController Delegate

extension MistCollectionViewController: UISearchControllerDelegate {
    
    func didDismissSearchController(_ searchController: UISearchController) {
        collectionView.isHidden = currentPage == 2 //because it gets unhidden for some reason
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        toggleHeaderVisibility(visible: true)
    }
    
}

    // MARK: - UISearchBarDelegate

extension MistCollectionViewController: UISearchBarDelegate {
    
    @objc func presentExploreSearchController() {
        mySearchController.searchBar.placeholder = "search for mists"
        mySearchController.searchBar.text = customNavBar.searchQueryButton.currentTitle
        present(mySearchController, animated: true) { [self] in
            searchSuggestionsVC.startProvidingCompletions(for: MKCoordinateRegion(center: mapView.region.center, latitudinalMeters: 100, longitudinalMeters: 100))
            mySearchController.searchBar.becomeFirstResponder() //needed bc after dismissing the newpost vc and then presenting mysearchcontroller, the keyboard doenst go up. not perfect, but it works
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchSuggestionsVC.searchResults.wordResults.count > 0 {
            tableView(searchSuggestionsVC.tableView, didSelectRowAt: IndexPath(row: 0, section: 0)) //cals the tableviewdelegate function just down below, as if they searched for that word
        } else {
            //do nothing. the search results just haven't loaded yet.
            
//            CustomSwiftMessages.showInfoCard("no results found", "please try again", emoji: "🙄")
//            mySearchController.isActive = false
        }
//        mySearchController.searchBar.resignFirstResponder() //DONT RESIGN bc otherwise the modal will be visible below
    }
        
}

// MARK: - UITableViewDelegate

extension MistCollectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let resultType = MapSearchResultType.init(rawValue: indexPath.section)!
        
        switch resultType {
        case .containing:
            let query = searchSuggestionsVC.searchResults.wordResults[indexPath.row]
            updateNavBarWithSearchQuery(searchText: query.text)
            handleTextSearchFor(searchText: query.text)
        case .nearby:
            if indexPath.row == 0 {
                let query = searchSuggestionsVC.searchResults.completerResults[indexPath.row].title
                updateNavBarWithSearchQuery(searchText: query.lowercased())
//                PostService.singleton.updateFilter(newSearchBy: .location)
                search(for: query)
            } else {
                let suggestion = searchSuggestionsVC.searchResults.completerResults[indexPath.row-1]
                updateNavBarWithSearchQuery(searchText: suggestion.title.lowercased())
//                PostService.singleton.updateFilter(newSearchBy: .location)
                search(for: suggestion) //first gets places from Apple, then calls reloadPosts(0
            }
        }
        mySearchController.isActive = false
    }
    
    @MainActor
    func handleTextSearchFor(searchText: String) {
        (collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? FeedCollectionCell)?.tableView.scrollToTop()
        (collectionView.cellForItem(at: IndexPath(item: 1, section: 0)) as? FeedCollectionCell)?.tableView.scrollToTop()
        PostService.singleton.updateFiltersWithWords(words: [searchText])
        Task {
            do {
                try await PostService.singleton.loadExploreFeedPostsIfPossible(feed: .RECENT)
                try await PostService.singleton.loadExploreFeedPostsIfPossible(feed: .TRENDING)
                try await PostService.singleton.loadAndOverwriteExploreMapPosts()
                DispatchQueue.main.async {
                    self.newFeedContentOffsetY = self.BASE_CONTENT_OFFSET
                    self.reloadAllData(animated: true)
                    self.renderNewPostsOnMap(withType: .firstLoad)

                    self.customNavBar.closeButton.loadingIndicator(false)
                    self.customNavBar.closeButton.setImage(CustomNavBar.CustomNavBarItem.close.image, for: .normal)
                }
            } catch {
                CustomSwiftMessages.displayError(error)
            }
        }
    }
    
    func updateNavBarWithSearchQuery(searchText: String) {
        customNavBar.configure(title: "", leftItems: [.searchQuery], rightItems: [.close])
        
        customNavBar.closeButton.addTarget(self, action: #selector(cancelSearchButtonPressed), for: .touchUpInside)
        customNavBar.closeButton.loadingIndicator(true)
        customNavBar.closeButton.setImage(nil, for: .normal)
        
        customNavBar.searchQueryButton.setTitle(searchText, for: .normal)
        customNavBar.searchQueryButton.addTarget(self, action: #selector(presentExploreSearchController), for: .touchUpInside)
    }
    
    @MainActor
    @objc func cancelSearchButtonPressed() {
        reloadButton.loadingIndicator(true)
        reloadButton.setImage(nil, for: .normal)
        customNavBar.closeButton.loadingIndicator(true)
        customNavBar.closeButton.setImage(nil, for: .normal)
        isFetchingMorePosts = true
        
        toggleHeaderVisibility(visible: true)
        PostService.singleton.updateFiltersWithWords(words: nil)
        removeExistingPlaceAnnotationsFromMap()
        (collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? FeedCollectionCell)?.tableView.scrollToTop()
        (collectionView.cellForItem(at: IndexPath(item: 1, section: 0)) as? FeedCollectionCell)?.tableView.scrollToTop()
        Task {
            do {
                try await PostService.singleton.loadExploreFeedPostsIfPossible(feed: .RECENT)
                try await PostService.singleton.loadExploreFeedPostsIfPossible(feed: .TRENDING)
                try await PostService.singleton.loadAndOverwriteExploreMapPosts()
                DispatchQueue.main.async {
                    self.renderNewPostsOnMap(withType: .firstLoad)
                    self.newFeedContentOffsetY = self.BASE_CONTENT_OFFSET
                    self.reloadAllData(animated: true)
                    
                    self.reloadButton.setImage(UIImage(systemName: "arrow.2.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)), for: .normal)
                    self.reloadButton.loadingIndicator(false)
                    self.isFetchingMorePosts = false
                    self.setupCustomNavBar(animated: true)
                    self.customNavBar.closeButton.loadingIndicator(false)
                    self.customNavBar.closeButton.setImage(CustomNavBar.CustomNavBarItem.close.image, for: .normal)
                    self.customNavBar.searchQueryButton.setTitle(nil, for: .normal)
                }
            } catch {
                CustomSwiftMessages.displayError(error)
                DispatchQueue.main.async {
                    self.reloadButton.setImage(UIImage(systemName: "arrow.2.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)), for: .normal)
                    self.reloadButton.loadingIndicator(false)
                    self.isFetchingMorePosts = false
                }
            }
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard
            let header:UITableViewHeaderFooterView = view as? UITableViewHeaderFooterView,
            let textLabel = header.textLabel
        else { return }
        //textLabel.font.pointSize is 13, seems kinda small
        textLabel.font = UIFont(name: Constants.Font.Roman, size: 15)
        textLabel.text = textLabel.text?.lowercased()//.capitalizeFirstLetter()
    }
    
}

// MARK: - Map Search

extension MistCollectionViewController {
    
    /// - Parameter suggestedCompletion: A search completion provided by `MKLocalSearchCompleter` when tapping on a search completion table row
    private func search(for suggestedCompletion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: suggestedCompletion)
        search(using: searchRequest)
    }
    
    /// - Parameter queryString: A search string from the text the user entered into `UISearchBar`
    //Not in use right now. We only let the user search via suggestions. If we let the user search for locations by typing in "star" and pressing search button, then we would need to uncomment this
    private func search(for queryString: String?) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = queryString
        search(using: searchRequest)
    }
    
    /// - Tag: SearchRequest
    private func search(using searchRequest: MKLocalSearch.Request) {
        searchRequest.region = MKCoordinateRegion(center: mapView.region.center, latitudinalMeters: 100, longitudinalMeters: 100) //setting a span that's smaller or larger seems to increase the frequency that apple will reset the search region to your current location. 10000 seems to be a good middle ground
        
        searchRequest.resultTypes = [.address, .pointOfInterest]
        let localSearch = MKLocalSearch(request: searchRequest)
        Task {
            do {
                let response = try await localSearch.start()
                if didAppleOverrideLocalSearchRegion(response.boundingRegion) {
                    CustomSwiftMessages.showInfoCard("no results found", "try adjusting the map and search again", emoji: "🧐")
                } else {
                    DispatchQueue.main.async { [self] in
                        appleregion = response.boundingRegion
                        flowLayout.scrollToPage(index: 2, animated: true)
                        turnPlacesIntoAnnotations(response.mapItems)
                        renderNewPlacesOnMap()
                        
                        self.customNavBar.closeButton.loadingIndicator(false)
                        self.customNavBar.closeButton.setImage(CustomNavBar.CustomNavBarItem.close.image, for: .normal)
                        //                    PostService.singleton.updateFilter(newRegion: getRegionCenteredAround(placeAnnotations)!)
                        //                    reloadPosts(withType: .newSearch)
                        //                    renderNewPostsOnFeedAndMap(withType: .newSearch)
                    }
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
        //this wasn't working properly: if you were actually looking at a region far from your current location and searched a region nearby your current location, apple gave a correct response region close to your current location, but we'd reject it. need a better algorithm
//        if let userLocation = locationManager.location {
//            if mapView.region.center.distance(from: userLocation.coordinate) > 10000 && responseRegion.center.distance(from: userLocation.coordinate) < 4000 {
//                return true
//            }
//        }
        return false
    }
    
}
