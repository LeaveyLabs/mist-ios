//
//  FeedTableViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class FeedTableViewController: UITableViewController {
    
    var selectedPostIndex: Int?
        
    override func viewDidLoad() {
        super.viewDidLoad();
        self.tableView.estimatedRowHeight = 100;
        self.tableView.rowHeight = UITableView.automaticDimension; // is this necessary?

        let nib = UINib(nibName: "PostCell", bundle: nil);
        self.tableView.register(nib, forCellReuseIdentifier: "PostCell");
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)

        refreshFeed();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.tableView.reloadData()
    }
    
    @objc func refreshFeed() {
        //good notes on managing Tasks:
        //https://www.swiftbysundell.com/articles/the-role-tasks-play-in-swift-concurrency/
        Task {
            do {
                try await PostService.homePosts.newPosts();
                self.tableView.reloadData();
                self.refreshControl!.endRefreshing()
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
        return PostService.homePosts.numberOfPosts();
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //tableview goes to look at the "reuse pool" for eligible cells to reuse
        //No -> create a brand new UITableViewCell
        //yes -> reuse it
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        cell.parentViewController = self
        let post = PostService.homePosts.getPost(at: indexPath.row)!
        
        cell.timestampLabel.text = getFormattedTimeString(postTimestamp: post.timestamp)
        cell.locationLabel.text = post.location
        cell.messageLabel.text = post.text
        cell.titleLabel.text = post.title
        
        //TODO: handle when there is not a post

        return cell
    }
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("post was tapped")
        selectedPostIndex = indexPath.row;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //TODO: how to know which comment button was pressed and correctly set selectedPostIndex?
        let postViewController = segue.destination as! PostViewController
        print("selected post index in feed:" + String(selectedPostIndex!))
        postViewController.post = PostService.homePosts.getPost(at: selectedPostIndex!)
    }
}
