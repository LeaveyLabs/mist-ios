//
//  FeedTableViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

// FeedViewController is an Abstract Class. Probably should change this to a protocol later on
class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var posts: [Post] = []
    var indicator = UIActivityIndicatorView()
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad();
        setupTableView()
        indicator = initActivityIndicator(onView: view)
        refreshFeed();
//        navigationController?.restoreHairline() //dont think this does anything...
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
        let feedHeader = UINib(nibName: Constants.SBID.Cell.FeedHeader, bundle: nil)
        tableView.register(feedHeader, forCellReuseIdentifier: Constants.SBID.Cell.FeedHeader)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.tableView.reloadData()
    }
    
    //MARK: -- Db Calls
    
    @objc dynamic func refreshFeed() {
        fatalError("This method must be overridden")
    }

    // MARK: -TableView Data Source

    dynamic func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fatalError("This method must be overridden")
    }
    
    dynamic func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("This method must be overridden")
    }
}


