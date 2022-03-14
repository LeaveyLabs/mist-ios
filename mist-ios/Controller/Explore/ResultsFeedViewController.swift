//
//  ResultsFeedViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class ResultsFeedViewController: FeedTableViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIGestureRecognizerDelegate {
    
    // MARK: -Properties
    var query: String!
    @IBOutlet weak var mistTitleView: UIView!
    var searchController: UISearchController!

    override func viewDidLoad() {
        searchController = UISearchController()
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.scopeButtonTitles = ["Posts", "Users"]
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self // Monitor when the search button is tapped.
        
        //(1 of 2) for enabling swipe left to go back with a bar button item
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self;
        
        let queryNib = UINib(nibName: Constants.SBID.Cell.Query, bundle: nil);
        self.tableView.register(queryNib, forCellReuseIdentifier: Constants.SBID.Cell.Query);
        
        navigationItem.titleView = mistTitleView
//        navigationController?.hidesBarsOnSwipe = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:))))
        
        super.viewDidLoad()
    }
    
    //(2 of 2) for enabling swipe left to go back with a bar button item
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: -Actions
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        searchController.dismiss(animated: true)
    }
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sortButtonDidPressed(_ sender: UIButton) {
        //customize sheet size before presenting
        //https://developer.apple.com/videos/play/wwdc2021/10063/
        let sortByVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.SortBy) as! SortByViewController

        if let sheet = sortByVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(sortByVC, animated: true, completion: nil)
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Query, for: indexPath) as! QueryCell
            cell.queryLabel.text = query
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        } else if (indexPath.row == 1) {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Sort, for: indexPath)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell;
        }
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
        cell.configurePostCell(post: posts[indexPath.row], parent: self)
        return cell
    }
    
    class func resultsFeedViewControllerForQuery(_ query: String) -> UIViewController {
        let viewController =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ResultsFeed) as! ResultsFeedViewController
        viewController.query = query
        return viewController
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        //
    }
    
}
