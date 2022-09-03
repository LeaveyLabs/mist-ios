//
//  NewPostViewController+Search.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/2/22.
//

import Foundation
import Foundation
import CoreLocation
import MapKit
    
//MARK: - Search Setup

extension NewPostViewController {
    
    var centeredCoordinate: CLLocationCoordinate2D {
        LocationManager.Shared.currentLocation?.coordinate ?? Constants.Coordinates.USC
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
        mySearchController.searchResultsUpdater = searchSuggestionsVC // requires conformance to UISearchResultsUpdating extension
        mySearchController.showsSearchResultsController = true //so white background is always visible
        mySearchController.delegate = self
        //searchBar
        mySearchController.searchBar.setValue("cancel", forKey: "cancelButtonText")
        mySearchController.searchBar.delegate = self // Monitor when the search button is tapped.
        mySearchController.searchBar.tintColor = cornerButtonGrey
        mySearchController.searchBar.searchTextField.tintColor = Constants.Color.mistLilac
        mySearchController.searchBar.autocapitalizationType = .none
        mySearchController.searchBar.searchBarStyle = .prominent //when setting to .minimal, the background disappears and you can see nav bar underneath. if using .minimal, add a background color to searchBar to fix this.
        mySearchController.searchBar.searchTextField.font = UIFont(name: Constants.Font.Roman, size: 18)
    }
    
}

    // MARK: - UISearchBarDelegate

extension NewPostViewController: UISearchBarDelegate {
        
    func presentExploreSearchController() {
        let isKeyboardUp = bodyTextView.isFirstResponder || titleTextView.isFirstResponder
        view.endEditing(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + (isKeyboardUp ? 0.3 : 0)) { [self] in
            mySearchController.searchBar.placeholder = MapSearchResultType.randomPlaceholder()
            present(mySearchController, animated: true) { [self] in
                searchSuggestionsVC.startProvidingCompletions(for: MKCoordinateRegion(center: centeredCoordinate, latitudinalMeters: 100, longitudinalMeters: 100))
                mySearchController.searchBar.becomeFirstResponder()
            }
        }
    }
        
}

extension NewPostViewController: UISearchControllerDelegate {
    
    func didDismissSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async { [self] in
            if titleTextView.text.isEmpty {
                titleTextView.becomeFirstResponder()
            } else {
                bodyTextView.becomeFirstResponder()
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension NewPostViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let suggestion = searchSuggestionsVC.completerResults[indexPath.row]
        PostService.singleton.updateFilter(newSearchBy: .location)
        search(for: suggestion)
        
        guard let cell = tableView.cellForRow(at: indexPath) as? SuggestedCompletionTableViewCell else { return }
        tableView.allowsSelection = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            cell.startLoadingAnimation()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard
            let header:UITableViewHeaderFooterView = view as? UITableViewHeaderFooterView,
            let textLabel = header.textLabel
        else { return }
        //textLabel.font.pointSize is 13, seems kinda small
        textLabel.font = UIFont(name: Constants.Font.Roman, size: 12)
        textLabel.text = textLabel.text?.lowercased()//.capitalizeFirstLetter()
    }
    
}

// MARK: - Map Search

extension NewPostViewController {
    
    
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
        searchRequest.region = MKCoordinateRegion(center: centeredCoordinate, latitudinalMeters: 100, longitudinalMeters: 100) //setting a span that's smaller or larger seems to increase the frequency that apple will reset the search region to your current location. 10000 seems to be a good middle ground
        
        searchRequest.resultTypes = [.address, .pointOfInterest]
        let localSearch = MKLocalSearch(request: searchRequest)
        Task {
            do {
                let response = try await localSearch.start()
                guard let foundSearchLocation = response.mapItems.first?.placemark else {
                    CustomSwiftMessages.showInfoCard("result not found", "please try searching again", emoji: "🙃")
                    return
                }
                handleFoundSearchLocation(placemark: foundSearchLocation)
            } catch {
                if let error = error as? MKError {
                    CustomSwiftMessages.displayError(error)
                    return
                }
            }
        }
    }
    
    func handleFoundSearchLocation(placemark: MKPlacemark) {
        currentlyPinnedPlacemark = placemark
        mySearchController.isActive = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { [self] in
            if titleTextView.text.isEmpty {
                titleTextView.becomeFirstResponder()
            } else {
                bodyTextView.becomeFirstResponder()
            }
            searchSuggestionsVC.tableView.allowsSelection = true
        })
    }
    
}
