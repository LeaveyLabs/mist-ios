//
//  SearchDebugViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/08.
//

import UIKit

class SearchDebugViewController: UIViewController, UISearchControllerDelegate {

    var mySearchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSearchBar()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        present(mySearchController, animated: true)
    }
    
    @IBAction func presentIt() {
        mySearchController.searchBar.setShowsScope(true, animated: false)
        present(mySearchController, animated: true)
    }
    
    func setupSearchBar() {
        //resultsTableViewController
        
        //searchController
        mySearchController = UISearchController(searchResultsController: nil)
        mySearchController.delegate = self
//        mySearchController.searchResultsUpdater = self
        mySearchController.showsSearchResultsController = true
        
        //https://stackoverflow.com/questions/68106036/presenting-uisearchcontroller-programmatically
        //this creates unideal ui, but im not going to spend more time trying to fix this right now.
        //mySearchController.hidesNavigationBarDuringPresentation = false //true by default

        //todo later: TWO WAYS OF MAKING SEARCH BAR PRETTY
        //definePresentationContext = false (plus) self.present(searchcontroller)
        //definePresentationContext = true (plus) navigationController?.present(searchController)
        definesPresentationContext = false //false by default
        
        //searchBar
        mySearchController.searchBar.delegate = self // Monitor when the search button is tapped.
        mySearchController.searchBar.scopeButtonTitles = []
        MapSearchScope.allCases.forEach { mapSearchScope in
            mySearchController.searchBar.scopeButtonTitles?.append(mapSearchScope.displayName)
        }
        mySearchController.searchBar.tintColor = .darkGray
        mySearchController.searchBar.autocapitalizationType = .none
        mySearchController.searchBar.searchBarStyle = .prominent //when setting to .minimal, the background disappears and you can see nav bar underneath. if using .minimal, add a background color to searchBar to fix this.
        mySearchController.searchBar.placeholder = "Search"
    }
    
    
    func presentSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        mySearchController.searchBar.setShowsScope(false, animated: false)
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
}

extension SearchDebugViewController: UISearchBarDelegate {
    
}
