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
        if !shouldFeedBeginVisible {
            view.sendSubviewToBack(feed)
        }
        NSLayoutConstraint.activate([
            feed.leftAnchor.constraint(equalTo: view.safeLeftAnchor),
            feed.rightAnchor.constraint(equalTo: view.safeRightAnchor),
            feed.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            feed.topAnchor.constraint(equalTo: mapView.topAnchor),
        ])
        
        feed.delegate = self
        feed.dataSource = self
        feed.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 50))
        feed.estimatedRowHeight = 100
        feed.rowHeight = UITableView.automaticDimension
        feed.showsVerticalScrollIndicator = false
        feed.separatorStyle = .none
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
        //in the feed, we don't need a reference to the postView like we do in 
        let _ = cell.configurePostCell(post: postAnnotations[indexPath.row].post,
                               nestedPostViewDelegate: self,
                               bubbleTrianglePosition: .left,
                               isWithinPostVC: false)
        return cell
    }
    
}

extension ExploreViewController: UITableViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
}

//MARK: - Helper

extension ExploreViewController {
    
    func scrollFeedToPostRightAboveKeyboard(_ postIndex: Int) {
        let postBottomYWithinFeed = feed.rectForRow(at: IndexPath(row: postIndex, section: 0))
        let postBottomY = feed.convert(postBottomYWithinFeed, to: view).maxY
        let keyboardTopY = view.bounds.height - keyboardHeight
        let desiredOffset = postBottomY - keyboardTopY
        if postIndex == 0 && desiredOffset < 0 { return } //dont scroll up for the very first post
        feed.setContentOffset(feed.contentOffset.applying(.init(translationX: 0, y: desiredOffset)), animated: true)
    }
}
