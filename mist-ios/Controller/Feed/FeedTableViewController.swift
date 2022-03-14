//
//  FeedTableViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class FeedTableViewController: UITableViewController {
    
    var selectedPostIndex: Int?
    @IBOutlet weak var mistTitle: UIView!
    var posts: [Post] = []
    var indicator = UIActivityIndicatorView()
        
    override func viewDidLoad() {
        super.viewDidLoad();
        self.tableView.estimatedRowHeight = 100;
        self.tableView.rowHeight = UITableView.automaticDimension; // is this necessary?


        navigationItem.titleView = mistTitle
        let nib = UINib(nibName: Constants.SBID.Cell.Post, bundle: nil);
        self.tableView.register(nib, forCellReuseIdentifier: Constants.SBID.Cell.Post);
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)

        initActivityIndicator()
        refreshFeed();
    }
    
    func initActivityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.medium
        indicator.center = CGPoint(x: UIScreen.main.bounds.size.width*0.5,y: UIScreen.main.bounds.size.height*0.4)
        indicator.hidesWhenStopped = true
        self.view.addSubview(indicator)
        indicator.startAnimating()
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
        cell.configurePostCell(post: posts[indexPath.row], parent: self)
        return cell
    }
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("post was tapped")
        selectedPostIndex = indexPath.row;
    }
}
