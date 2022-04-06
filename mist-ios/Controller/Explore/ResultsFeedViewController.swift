//
//  ResultsFeedViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class ResultsFeedViewController: FeedTableViewController, UIGestureRecognizerDelegate {
    
    // MARK: -Properties
    var query: String!
    
    // MARK: -Life Cycle

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
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self;
        
        let queryNib = UINib(nibName: Constants.SBID.Cell.Query, bundle: nil);
        self.tableView.register(queryNib, forCellReuseIdentifier: Constants.SBID.Cell.Query);
        
        navigationController?.restoreHairline()
        navigationItem.title = query
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:))))
        //navigationController?.navigationBar.standardAppearance.backgroundColor = hexStringToUIColor(hex: "CDABE1", alpha: offset/2)

        super.viewDidLoad()
    }
    
    //MARK: -Custom Constructors
    
    class func resultsFeedViewControllerForQuery(_ query: String) -> UIViewController {
        let viewController =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ResultsFeed) as! ResultsFeedViewController
        viewController.query = query
        return viewController
    }
    
    // MARK: -User Interaction
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        //
    }
    
    @IBAction func backButtonDidPressed(_ sender: UIBarButtonItem) {
        navigationController?.hideHairline()
        navigationController?.popViewController(animated: true)
    }
    
    //(2 of 2) for enabling swipe left to go back with a bar button item
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        navigationController?.hideHairline()
        return true
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
    
    // MARK: -API calls
    
    @objc override func refreshFeed() {
        //TODO: cancel task if it takes too long. that way the user can refresh and try again
        Task {
            do {
                posts = try await PostAPI.fetchPosts(text: query)
                self.tableView.reloadData();
                refreshControl!.endRefreshing()
                indicator.stopAnimating()
                print("loaded")
            } catch {
                print(error)
            }
        }
    }
    
    // MARK: -..?

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
    
    // MARK: -TableView Delegate & Data Source
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(indexPath)
        if (indexPath.row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Query, for: indexPath) as! QueryCell
            cell.queryLabel.text = query
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        }
        else  if (indexPath.row == 1) {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Sort, for: indexPath)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell;
        }
        let cell = self.tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
        cell.configurePostCell(post: posts[indexPath.row-2], parent: self, bubbleArrowPosition: .left)
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2 + posts.count
    }
    
}
