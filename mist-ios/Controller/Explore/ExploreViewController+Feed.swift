//
//  ExploreViewController+Feed.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/11.
//

import Foundation
import UIKit

//MARK: - Table View Setup

extension ExploreViewController {
    
    func setupTableView() {
        feed = UITableView()
        feed.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(feed)
        view.sendSubviewToBack(feed)
        view.bringSubviewToFront(customNavigationBar) //important for when re-inserting tableView below view later on
        NSLayoutConstraint.activate([
            feed.leftAnchor.constraint(equalTo: view.safeLeftAnchor),
            feed.rightAnchor.constraint(equalTo: view.safeRightAnchor),
            feed.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            feed.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor),
        ])
        
        feed.dataSource = self
        feed.estimatedRowHeight = 100
        feed.rowHeight = UITableView.automaticDimension
        feed.showsVerticalScrollIndicator = false
        feed.separatorStyle = .none
        feed.refreshControl = UIRefreshControl()
        feed.refreshControl!.addAction(.init(handler: { [self] _ in
            reloadPosts(withType: .refresh)
        }), for: .valueChanged)
        
        feed.register(PostCell.self, forCellReuseIdentifier: Constants.SBID.Cell.Post)
    }
    
}

//MARK: - TableViewDataSource

extension ExploreViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postAnnotations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.feed.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
        cell.selectionStyle = .none
        cell.configurePostCell(post: postAnnotations[indexPath.row].post,
                               nestedPostViewDelegate: self,
                               bubbleTrianglePosition: .left,
                               isWithinPostVC: false)
        return cell
    }
    
}
