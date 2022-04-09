//
//  FeedTableViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var posts: [Post] = []
    var indicator = UIActivityIndicatorView()
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad();
        setupTableView()
        indicator = initActivityIndicator(onView: view)
        refreshFeed();
        navigationController?.restoreHairline() //dont think this does anything...
    }
    
    //MARK: -- Setup
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100;
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl!.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)

        let nib = UINib(nibName: Constants.SBID.Cell.Post, bundle: nil);
        self.tableView.register(nib, forCellReuseIdentifier: Constants.SBID.Cell.Post);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.tableView.reloadData()
    }
    
    //MARK: -- Db Calls
    
    @objc func refreshFeed() {
        //good notes on managing Tasks:
        //https://www.swiftbysundell.com/articles/the-role-tasks-play-in-swift-concurrency/
        //TODO: cancel task if it takes too long. that way the user can refresh and try again
        Task {
            do {
                posts = try await PostAPI.fetchPosts();
                self.tableView.reloadData();
                tableView.refreshControl!.endRefreshing()
                indicator.stopAnimating()
                print("loaded")
            } catch {
                print(error)
            }
        }
    }

    // MARK: -TableView Data Source

    dynamic func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    dynamic func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    dynamic func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
        cell.configurePostCell(post: posts[indexPath.row], parent: self, bubbleArrowPosition: .left)
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        return cell
    }
    
    // MARK: - TableView Delegate
    
    dynamic func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //do nothing
    }
}


