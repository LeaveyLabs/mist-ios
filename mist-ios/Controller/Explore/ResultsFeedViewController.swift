//
//  ResultsFeedViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

enum FeedType {
    case home
    case query
    case mine
    case hotspot
}

class ResultsFeedViewController: FeedViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    var feedType: FeedType!
    var feedValue: String!
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        //something to do with edge insets.....
//        self.edgesForExtendedLayout = UIRectEdge()
//        self.extendedLayoutIncludesOpaqueBars = false
        
//        tableView.tableFooterView = UIView()
//        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
//        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);
        
//        tableView.estimatedRowHeight = 80
//        tableView.rowHeight = UITableView.automaticDimension
        
        //(1 of 2) for enabling swipe left to go back with a bar button item
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        tableView.refreshControl = nil //disable pull down top refresh
        
//        navigationController?.restoreHairline() //TODO: does nothing
        navigationItem.title = feedValue
        //navigationController?.navigationBar.standardAppearance.backgroundColor = hexStringToUIColor(hex: "CDABE1", alpha: offset/2)

        super.viewDidLoad()
    }
    
    //MARK: - Custom Constructors
    
    class func resultsFeedViewController(feedType: FeedType, feedValue: String) -> ResultsFeedViewController {
        let viewController =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ResultsFeed) as! ResultsFeedViewController
        viewController.feedValue = feedValue
        viewController.feedType = feedType
        return viewController
    }
    
    // MARK: - User Interaction
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    //(2 of 2) for enabling swipe left to go back with a bar button item
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // MARK: - API calls
    
    // Defines how the list brings in posts
    @objc override func refreshFeed() {
        //TODO: cancel task if it takes too long. that way the user can refresh and try again
        switch feedType {
        case .hotspot: //if hotspot, the posts will have already been set beforehand, so do nothing
            indicator.stopAnimating()
            return
        case .mine: //if mine, just set posts to authed user's posts
            indicator.stopAnimating()
            return
        case .query: //if query, query those posts
            Task {
                do {
                    posts = try await PostAPI.fetchPostsByText(text: feedValue)
                    tableView.reloadData();
                    indicator.stopAnimating()
                } catch {
                    print(error)
                }
            }
        case .home:
            return
        case .none:
            return
        }
    }
    
    // MARK: -..?

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //TODO: dynamically set starting offset so it works for all screen sizes, not just the 12
        let startingOffset: CGFloat = 50
        var offset = (tableView.contentOffset.y + startingOffset) / 100
        if (offset > 1) {
            offset = 1
//            navigationController?.navigationBar.standardAppearance.backgroundColor = hexStringToUIColor(hex: "CDABE1", alpha: offset/2)
            navigationController?.navigationBar.standardAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: offset)]
        } else {
//            navigationController?.navigationBar.standardAppearance.backgroundColor = hexStringToUIColor(hex: "CDABE1", alpha: offset/2)
            navigationController?.navigationBar.scrollEdgeAppearance?.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: offset)]
            navigationController?.navigationBar.standardAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor(white: 0, alpha: offset)]
        }
    }
    
    // MARK: - UITableViewDelegate
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.FeedHeader, for: indexPath) as! FeedHeaderCell
            cell.feedHeaderLabel.text = feedValue
            cell.feedType = feedType
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        }
        let cell = self.tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
        cell.configurePostCell(post: posts[indexPath.row-1], bubbleTrianglePosition: .left)
        cell.postDelegate = self
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + posts.count
    }
    
    
    
}

//MARK: - Post Delegation: functions with implementations unique to this class

extension ResultsFeedViewController: PostDelegate {
    
    func backgroundDidTapped(post: Post) {
        sendToPostViewFor(post, withRaisedKeyboard: false)
    }
    
    func commentDidTapped(post: Post) {
        sendToPostViewFor(post, withRaisedKeyboard: true)
    }
    
    // Helpers
    
    func sendToPostViewFor(_ post: Post, withRaisedKeyboard: Bool) {
        let postVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
        postVC.post = post
        postVC.shouldStartWithRaisedKeyboard = withRaisedKeyboard
        postVC.completionHandler = { Post in
            self.tableView.reloadData()
        }
        navigationController!.pushViewController(postVC, animated: true)
    }
}
