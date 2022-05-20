//
//  ExploreFeedViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/08.
//

import UIKit

class ExploreFeedViewController: FeedViewController {
    
    @IBOutlet weak var mistTitle: UIView!
        
    //ExploreViewController
    var mySearchController: UISearchController!
    private var resultsTableController: LiveResultsTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = mistTitle
                
        //ExploreViewController
        setupSearchBar()
    }
    
    @objc override func refreshFeed() {
        Task {
            do {
                posts = try await PostAPI.fetchPosts();
                self.tableView.reloadData();
                tableView.refreshControl!.endRefreshing()
                indicator.stopAnimating()
            } catch {
                print(error)
            }
        }
    }
    
    //MARK: - Setup
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
}

//MARK: - FeedHeaderCellDelegate

extension ExploreFeedViewController: FeedHeaderCellDelegate {
    func handleFilterButtonPress() {
        //customize sheet size before presenting
        //https://developer.apple.com/videos/play/wwdc2021/10063/
        let sortByVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.SortBy) as! SortByViewController

        if let sheet = sortByVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(sortByVC, animated: true, completion: nil)
    }
}

//MARK: --------------ExploreViewController

extension ExploreFeedViewController {

    // MARK: - User Interaction
    
    @IBAction func searchButtonDidPressed(_ sender: UIBarButtonItem) {
        present(mySearchController, animated: true)
    }
    
    @IBAction func mapButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: false)
    }
    
    //TODO: add custom animations
    //https://stackoverflow.com/questions/51675063/how-to-present-view-controller-from-left-to-right-in-ios
    //https://github.com/HeroTransitions/Hero
    @IBAction func myProfileButtonDidTapped(_ sender: UIBarButtonItem) {
        let myAccountNavigation = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation)
        myAccountNavigation.modalPresentationStyle = .fullScreen
        self.navigationController?.present(myAccountNavigation, animated: true, completion: nil)
    }
}

extension ExploreFeedViewController: UISearchControllerDelegate {
    func setupSearchBar() {
        //resultsTableViewController
        resultsTableController =
        self.storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.LiveResults) as? LiveResultsTableViewController
        resultsTableController.tableView.delegate = self // This view controller is interested in table view row selections.
        resultsTableController.tableView.contentInsetAdjustmentBehavior = .automatic //removes strange whitespace https://stackoverflow.com/questions/1703023/is-it-possible-to-access-a-uitableviews-scrollview-in-code-from-a-nib
        
        resultsTableController.resultsLabelView.isHidden = true

        //searchController
        mySearchController = UISearchController(searchResultsController: resultsTableController)
        mySearchController.delegate = self
        mySearchController.searchResultsUpdater = self
        mySearchController.showsSearchResultsController = true //means that we don't need "map cover view" anymore
        
        //https://stackoverflow.com/questions/68106036/presenting-uisearchcontroller-programmatically
        //this creates unideal ui, but im not going to spend more time trying to fix this right now.
        //mySearchController.hidesNavigationBarDuringPresentation = false //true by default

        //todo later: TWO WAYS OF MAKING SEARCH BAR PRETTY
        //definePresentationContext = false (plus) self.present(searchcontroller)
        //definePresentationContext = true (plus) navigationController?.present(searchController)
        definesPresentationContext = true //false by default
        
        //searchBar
        mySearchController.searchBar.tintColor = .darkGray
        mySearchController.searchBar.delegate = self // Monitor when the search button is tapped.
        mySearchController.searchBar.autocapitalizationType = .none
        mySearchController.searchBar.searchBarStyle = .prominent //when setting to .minimal, the background disappears and you can see nav bar underneath. if using .minimal, add a background color to searchBar to fix this.
        mySearchController.searchBar.placeholder = "Search"
    }
}

    // MARK: - UISearchBarDelegate

extension ExploreFeedViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = mySearchController.searchBar.text else { return }

        switch resultsTableController.selectedScope {
            case 0:
                //TODO: idea: what if you present a new navigation controller , with its root view controller as the newQueryFeedViewController. will this fix aesthetic issues?
            let newQueryFeedViewController = ResultsFeedViewController.resultsFeedViewController(feedType: .query, feedValue: text)
                navigationController?.pushViewController(newQueryFeedViewController, animated: true)
            case 1:
                break
            default: break
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        resultsTableController.selectedScope = selectedScope
        resultsTableController.liveResults = []
        updateSearchResults(for: mySearchController)
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
}

    // MARK: - UITableViewDelegate

extension ExploreFeedViewController {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        // We only care about the ResultsTableView and not the FeedTableView
        if tableView === resultsTableController.tableView {
            switch resultsTableController.selectedScope {
            case 0:
                let word = resultsTableController.liveResults[indexPath.row] as! Word
                let newQueryFeedViewController = ResultsFeedViewController.resultsFeedViewController(feedType: .query, feedValue: word.text)
                navigationController?.pushViewController(newQueryFeedViewController, animated: true)
            default: break
            }
        }
    }
}

    // MARK: - UITableViewDataSource

extension ExploreFeedViewController {
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.FeedHeader, for: indexPath) as! FeedHeaderCell
//            cell.feedHeaderLabel.text = "\(filter)"
            cell.feedType = .home
            cell.delegate = self
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        }
        let cell = self.tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
        cell.configurePostCell(post: posts[indexPath.row], parent: self, bubbleArrowPosition: .left)
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        return cell
    }
}


    // MARK: - UISearchControllerDelegate

extension ExploreFeedViewController {
    
    func presentSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
//        navigationController?.hideHairline()
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        navigationItem.searchController = searchController
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
        print("will dismiss sc")
//        navigationController?.restoreHairline()
        navigationItem.searchController = .none
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
    
}

extension ExploreFeedViewController: UISearchResultsUpdating {
    
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
                    case 0:
                        resultsController.liveResults = try await WordAPI.fetchWords(text: text)
                    case 1:
                        print("doing a profile search with: " + text)
                        resultsController.liveResults = try await UserAPI.fetchUsersByText(text: text)
                    default: break
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

