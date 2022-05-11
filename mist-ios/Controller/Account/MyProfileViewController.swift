//
//  MyProfileViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/29.
//

import UIKit

//TODO: badges
//https://github.com/jogendra/BadgeHub

class MyProfileViewController: FeedViewController {
    
    var selectedFeedIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - UserInteraction
    
    @IBAction func onExitButtonPressed(_ sender: UIBarButtonItem) {
//        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true)
    }
        
    //MARK: -- Overrides
    
    
    //good notes on managing Tasks:
    //https://www.swiftbysundell.com/articles/the-role-tasks-play-in-swift-concurrency/
    @objc override func refreshFeed() {
        //TODO: cancel task if it takes too long. that way the user can refresh and try again
        Task {
            do {
                //TODO: change postAPI call based on the selectedFeedIndex
                switch selectedFeedIndex {
                case 0:
                    posts = try await PostAPI.fetchPosts();
                case 1:
                    posts = try await PostAPI.fetchPosts();
                default:
                    posts = try await PostAPI.fetchPosts();
                }
                tableView.reloadData();
                tableView.refreshControl!.endRefreshing()
                indicator.stopAnimating()
            } catch {
                print(error)
            }
        }
    }

    dynamic override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //+2 is for the profile cell and the segmented control cell
        return posts.count + 2
    }
    
    dynamic override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath)
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        case 1:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "SegmentedControlCell", for: indexPath) as! SegmentedControlCell
            cell.configureSegmentedControlCell(parent: self)
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        default:
            let cell = self.tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
            cell.configurePostCell(post: posts[indexPath.row], parent: self, bubbleArrowPosition: .left)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        }
    }
    
}
