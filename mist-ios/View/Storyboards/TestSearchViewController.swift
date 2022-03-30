//
//  TestSearchViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/25.
//

import UIKit

class TestSearchViewController: UIViewController {

    var searchController: UISearchController!
    @IBOutlet weak var searchButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.isActive = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.scopeButtonTitles = ["Posts", "Users"]
//        searchController.delegate = self
//        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
//        searchController.searchBar.delegate = self // Monitor when the search button is tapped.
    
        searchController.hidesNavigationBarDuringPresentation = true
//        navigationItem.searchController = searchController
//        navigationItem.titleView = mistTitle
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func searchButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.present(searchController, animated: true)
//        searchController.searchBar.becomeFirstResponder()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
