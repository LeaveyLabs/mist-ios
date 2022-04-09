//
//  FeedTableViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class FeedTableViewController: UITableViewController {
    
    var posts: [Post] = []
    var indicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad();
        self.tableView.estimatedRowHeight = 100;
        self.tableView.rowHeight = UITableView.automaticDimension; // is this necessary?
        tableView.showsVerticalScrollIndicator = false

        let nib = UINib(nibName: Constants.SBID.Cell.Post, bundle: nil);
        self.tableView.register(nib, forCellReuseIdentifier: Constants.SBID.Cell.Post);
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
        
        indicator = initActivityIndicator(onView: view)
        refreshFeed();
        navigationController?.restoreHairline()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.tableView.reloadData()
    }
    
    @objc func refreshFeed() {
        //good notes on managing Tasks:
        //https://www.swiftbysundell.com/articles/the-role-tasks-play-in-swift-concurrency/
        //TODO: cancel task if it takes too long. that way the user can refresh and try again
        Task {
            do {
                posts = try await PostAPI.fetchPosts();
                self.tableView.reloadData();
                refreshControl!.endRefreshing()
                indicator.stopAnimating()
                print("loaded")
            } catch {
                print(error)
            }
        }
    }

    // MARK: -TableView Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
        cell.configurePostCell(post: posts[indexPath.row], parent: self, bubbleArrowPosition: .left)
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        return cell
    }
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //do nothing
    }
}


