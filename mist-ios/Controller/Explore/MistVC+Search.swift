//
//  ExploreViewController+Search.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/12/22.
//

import Foundation
import CoreLocation
    
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
        mySearchController.searchBar.text = customNavBar.searchQueryButton.currentTitle?.replacingOccurrences(of: ",", with: "")
        present(mySearchController, animated: true) { [self] in
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
        guard
            let displayQuery = mySearchController.searchBar.text?.condensed.replacingOccurrences(of: " ", with: ", "),
            let searchQuery = mySearchController.searchBar.text?.condensed.components(separatedBy: .whitespaces)
        else {
            CustomSwiftMessages.displayError("something went wrong", "")
            return
        }
        updateNavBarWithSearchQuery(searchText: displayQuery)
        handleTextSearchFor(searchText: searchQuery)
        mySearchController.isActive = false
    }
    
    @MainActor
    func handleTextSearchFor(searchText: [String]) {
        (collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? FeedCollectionCell)?.tableView.scrollToTop()
        (collectionView.cellForItem(at: IndexPath(item: 1, section: 0)) as? FeedCollectionCell)?.tableView.scrollToTop()
        PostService.singleton.updateFiltersWithWords(words: searchText)
        Task {
            do {
                try await PostService.singleton.loadExploreFeedPostsIfPossible(feed: .RECENT)
                try await PostService.singleton.loadExploreFeedPostsIfPossible(feed: .TRENDING)
                DispatchQueue.main.async {
                    self.newFeedContentOffsetY = self.BASE_CONTENT_OFFSET
                    self.reloadAllData(animated: true)
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
        customNavBar.closeButton.loadingIndicator(true)
        customNavBar.closeButton.setImage(nil, for: .normal)
        isFetchingMorePosts = true
        
        toggleHeaderVisibility(visible: true)
        PostService.singleton.updateFiltersWithWords(words: nil)
        (collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? FeedCollectionCell)?.tableView.scrollToTop()
        (collectionView.cellForItem(at: IndexPath(item: 1, section: 0)) as? FeedCollectionCell)?.tableView.scrollToTop()
        Task {
            do {
                try await PostService.singleton.loadExploreFeedPostsIfPossible(feed: .RECENT)
                try await PostService.singleton.loadExploreFeedPostsIfPossible(feed: .TRENDING)
                DispatchQueue.main.async {
                    self.newFeedContentOffsetY = self.BASE_CONTENT_OFFSET
                    self.reloadAllData(animated: true)
                    
                    self.isFetchingMorePosts = false
                    self.setupCustomNavBar(animated: true)
                    self.customNavBar.closeButton.loadingIndicator(false)
                    self.customNavBar.closeButton.setImage(CustomNavBar.CustomNavBarItem.close.image, for: .normal)
                    self.customNavBar.searchQueryButton.setTitle(nil, for: .normal)
                }
            } catch {
                CustomSwiftMessages.displayError(error)
                DispatchQueue.main.async {
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
