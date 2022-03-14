//
//  ResultsTableViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class LiveResultsTableViewController: UITableViewController {
    
    //MARK: -Properties
        
    /// Data models for the table view.
    var selectedScope = 0
    //var users = [User]()
    var postResults = [Post]()
    
    @IBOutlet weak var resultsLabel: UILabel!
    
    //MARK: -Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsLabel.isHidden = true;

        let nib = UINib(nibName: Constants.SBID.Cell.PostResult, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: Constants.SBID.Cell.PostResult)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.PostResult, for: indexPath)
        let post = postResults[indexPath.row]
        
        cell.textLabel?.text = post.title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPost = postResults[indexPath.row]
        
        switch selectedScope {
        case 0:
            break
        case 1:
            break
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
