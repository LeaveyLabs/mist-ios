//
//  ExploreMapViewController+Search.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/05.
//

import Foundation

//MARK: - SearchViewController Extension
    
extension ExploreMapViewController {
    
    // MARK: - User Interaction
    
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

extension ExploreMapViewController: UISearchControllerDelegate {
    func setupSearchBar() {
        //self
        definesPresentationContext = true //necessary so that pushes go to the next controller

        //resultsTableViewController
        resultsTableController = self.storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.LiveResults) as? LiveResultsTableViewController
        resultsTableController.tableView.delegate = self
        resultsTableController.tableView.contentInsetAdjustmentBehavior = .automatic //necessary for setting bottom insets properly
        
        //searchController
        mySearchController = UISearchController(searchResultsController: resultsTableController)
        mySearchController.delegate = self
        mySearchController.searchResultsUpdater = self
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
    
    func presentSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        
        mySearchController.searchBar.placeholder = resultsTableController.selectedScope.randomPlaceholder
        present(mySearchController, animated: true) {
            self.mySearchController.searchBar.showsScopeBar = true //needed to prevent weird animation
            self.resultsTableController.tableView.contentInset.top -= self.view.safeAreaInsets.top - 10 //needed bc auto content inset adjustment behavior isn't reflecing safeareainsets for some reason
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

extension ExploreMapViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = mySearchController.searchBar.text else { return }

        switch resultsTableController.selectedScope {
        case .locatedAt:
            break
        case .containing:
            let newQueryFeedViewController = ResultsFeedViewController.resultsFeedViewController(feedType: .query, feedValue: text)
            navigationController?.pushViewController(newQueryFeedViewController, animated: true)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let newSelectedScope = MapSearchScope(rawValue: selectedScope) else { return }
        resultsTableController.selectedScope = newSelectedScope
        mySearchController.searchBar.placeholder = resultsTableController.selectedScope.randomPlaceholder
        resultsTableController.liveResults = []
        updateSearchResults(for: mySearchController)
    }
}

    // MARK: - UITableViewDelegate

extension ExploreMapViewController: UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        switch resultsTableController.selectedScope {
        case .locatedAt:
            break
        case .containing:
            let word = resultsTableController.liveResults[indexPath.row] as! Word
            let newQueryFeedViewController = ResultsFeedViewController.resultsFeedViewController(feedType: .query, feedValue: word.text)
            navigationController?.pushViewController(newQueryFeedViewController, animated: true)
        }
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
                    case .locatedAt:
                        break
                    case .containing:
                        resultsController.liveResults = try await WordAPI.fetchWords(text: text)
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
