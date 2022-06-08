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
    var selectedScope: MapSearchScope = .init(rawValue: 0)!
    var liveResults = [Any]()
    
    @IBOutlet weak var resultsLabel: UILabel!
    @IBOutlet weak var resultsLabelView: UIView!
    
    //MARK: -Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: Constants.SBID.Cell.WordResult, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: Constants.SBID.Cell.WordResult)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return liveResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedScope {
        case .locatedAt:
            return UITableViewCell()
        case .containing:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.WordResult, for: indexPath) as! WordResultCell
            cell.configureWordCell(word: liveResults[indexPath.row] as! Word, parent: self)
            return cell
        }
        
        //Not allowing searching for users for now
//            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.UserResult, for: indexPath) as! UserResultCell
//            cell.configureUserCell(user: liveResults[indexPath.row] as! User, parent: self)
//            return cell
    }
}
