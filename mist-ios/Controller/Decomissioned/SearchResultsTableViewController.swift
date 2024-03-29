////
////  ResultsFeedViewController.swift
////  mist-ios
////
////  Created by Adam Novak on 2022/03/13.
////
//
//import UIKit
//
//class SearchResultsTableViewController: FeedViewController {
//    
//    // MARK: - Properties
//    
//    var feedType: FeedType!
//    var feedValue: String!
//    
//    //PostDelegate
//    var loadAuthorProfilePicTasks: [Int: Task<FrontendReadOnlyUser?, Never>] = [:]
//    
//    // MARK: - Life Cycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        tableView.estimatedRowHeight = 80
//        tableView.refreshControl = nil //disable pull down top refresh
//        tableView.separatorStyle = .none
//        navigationItem.title = feedValue
//        tableView.register(PostCell.self, forCellReuseIdentifier: Constants.SBID.Cell.Post)
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        disableInteractivePopGesture()
//    }
//    
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        enableInteractivePopGesture()
//    }
//    
//    //MARK: - Custom Constructors
//    
//    class func resultsFeedViewController(feedType: FeedType, feedValue: String) -> SearchResultsTableViewController {
//        let viewController =
//        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ResultsFeed) as! SearchResultsTableViewController
//        viewController.feedValue = feedValue
//        viewController.feedType = feedType
//        return viewController
//    }
//    
//    // MARK: - User Interaction
//    
//    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
//        navigationController?.popViewController(animated: true)
//    }
//
//    // MARK: - API calls
//    
//    // Defines how the list brings in posts
//    @objc override func refreshFeed() {
//        switch feedType {
//        case .hotspot: //if hotspot, the posts will have already been set beforehand, so do nothing
//            indicator.stopAnimating()
//            return
//        case .mine: //if mine, just set posts to authed user's posts
//            indicator.stopAnimating()
//            return
//        case .query: //if query, query those posts
//            Task {
//                do {
//                    posts = try await PostAPI.fetchPostsByWords(words: [feedValue])
//                    tableView.reloadData();
//                    indicator.stopAnimating()
//                } catch {
//                    CustomSwiftMessages.displayError(error)
//                }
//            }
//        case .home:
//            return
//        case .none:
//            return
//        }
//    }
//    
//    // MARK: -..?
//
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let startingOffset: CGFloat = self.view.safeAreaInsets.top - 30
//        var offset = (tableView.contentOffset.y + startingOffset) / 100
//        if (offset > 1) {
//            offset = 1
//            navigationController?.navigationBar.standardAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: offset)]
//        } else {
//            navigationController?.navigationBar.scrollEdgeAppearance?.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: offset)]
//            navigationController?.navigationBar.standardAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: offset)]
//        }
//    }
//        
//    // MARK: - UITableViewDataSource
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if (indexPath.row == 0) {
//            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.FeedHeader, for: indexPath) as! FeedHeaderCell
//            cell.feedHeaderLabel.text = feedValue
//            cell.feedType = feedType
//            return cell
//        }
//        let cell = self.tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
////        cell.configurePostCell(post: posts[indexPath.row-1], nestedPostViewDelegate: self, bubbleTrianglePosition: .left, isWithinPostVC: false)
//        return cell
//    }
//    
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 1 + posts.count
//    }
//    
//}
