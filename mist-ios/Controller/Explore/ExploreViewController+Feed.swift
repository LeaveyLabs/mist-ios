//
//  ExploreViewController+Feed.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/11.
//

import Foundation
import UIKit

//MARK: - Table View

//MARK: - Table View Setup

extension ExploreViewController {
    
    func setupTableView() {
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.bringSubviewToFront(searchButton)
        view.bringSubviewToFront(toggleMapFilterButton)
        view.bringSubviewToFront(filterButton)
        let constraints = [
            tableView.leftAnchor.constraint(equalTo: view.safeLeftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeRightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        
        tableView.isHidden = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl!.addTarget(self, action: #selector(reloadPosts as () -> ()), for: .valueChanged)
        
        let nib = UINib(nibName: Constants.SBID.Cell.Post, bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: Constants.SBID.Cell.Post)
    }
    
}

extension ExploreViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postAnnotations.count + 1 //+ 1 for the offset
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = UITableViewCell()
            cell.translatesAutoresizingMaskIntoConstraints = false
            cell.heightAnchor.constraint(equalToConstant: filterButton.frame.height + 15).isActive = true
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        }
        let cell = self.tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
        cell.configurePostCell(post: postAnnotations[indexPath.row].post, bubbleTrianglePosition: .left)
        cell.postDelegate = self
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        return cell
    }
    
}