//
//  FeedTableViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class FeedTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad();
        self.tableView.estimatedRowHeight = 100;
        self.tableView.rowHeight = UITableView.automaticDimension; // is this necessary?

        let nib = UINib(nibName: "PostTableViewCell", bundle: nil);
        self.tableView.register(nib, forCellReuseIdentifier: "PostTableViewCell");
        
        //for when going to comments
        navigationController!.hidesBottomBarWhenPushed = true

        // Uncomment the following line to preserve selection between presentations ? Adam: What does this mean
        // self.clearsSelectionOnViewWillAppear = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        refreshPosts();
    }
    
    
    func refreshPosts() {
        //use DispatchQueue.main.async somehow
        self.tableView.reloadData();
    }

    // MARK: -TableView Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10;
        //return PostService.homePosts.numberOfPosts();
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //tableview goes to look at the "reuse pool" for eligible cells to reuse
        //No -> create a brand new UITableViewCell
        //yes -> reuse it
        //let cell = postsTableView.dequeueReusableCell(withIdentifier: "PostTableCell")!
        //force casting with "as!" gives us access to its properties
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as! PostTableViewCell
        cell.parentViewController = self
        //let post = PostService.homePosts.getPost(at: indexPath.row)!
        
//        cell.timestampLabel.text = getFormattedTimeString(postTimestamp: post.getTimestamp())
//        cell.wordLabel.text = post.getWord()
//        cell.usernameLabel.text = "@" + post.getUsername()
//        cell.definitionLabel.text = post.getDefinition()
//        cell.quoteLabel.text = post.getQuote()
//        cell.upvoteButton.setTitle(" \(post.getUpvotes()) 개", for: .normal)
        
        //TODO: handle when there is not a post

        return cell
    }
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("post was tapped")
    }
    
}
