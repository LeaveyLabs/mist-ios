//
//  FeedOverlayViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/30/22.
//

import Foundation
import UIKit

//MARK: - Table View Setup

class FeedOverlayViewController: UIViewController {
    
    var posts = PostService.singleton.getExplorePosts()
    var postDelegate: PostDelegate!
    
    @IBOutlet weak var feed: PostTableView!
    @IBOutlet weak var notchHandleView: UIView!
    @IBOutlet weak var notchView: UIView!
    @IBOutlet weak var profilePicButton: UIButton!
    @IBOutlet weak var notchViewHeightConstraint: NSLayoutConstraint!
    
    class func create(postDelegate: PostDelegate) -> FeedOverlayViewController {
        let feedOverlay = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: "FeedOverlayViewController") as! FeedOverlayViewController
        feedOverlay.postDelegate = postDelegate
        return feedOverlay
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotchView()
        setupTableView()
        view.backgroundColor = .clear
        profilePicButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
    }
    
    func setupNotchView() {
        notchView.layer.cornerCurve = .continuous
        notchView.layer.cornerRadius = 20
        notchView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Top right corner, Top left corner respectively
        notchView.applyMediumTopOnlyShadow()
        notchHandleView.layer.cornerCurve = .continuous
        notchHandleView.layer.cornerRadius = 2
    }
    
    func setupTableView() {
        feed.backgroundColor = Constants.Color.offWhite
        feed.clipsToBounds = true
        feed.delegate = self
        feed.dataSource = self
        feed.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: 100, height: 50))
        feed.estimatedRowHeight = 100
        feed.rowHeight = UITableView.automaticDimension
        feed.showsVerticalScrollIndicator = false
        feed.separatorStyle = .none
        feed.register(PostCell.self, forCellReuseIdentifier: Constants.SBID.Cell.Post)
    }
    
    //MARK: - UserInteraction
    
    @IBAction func onProfilePicPress() {
        guard
            let myAccountNavigation = storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation) as? UINavigationController,
            let myAccountVC = myAccountNavigation.topViewController as? MyAccountViewController
        else { return }
        myAccountNavigation.modalPresentationStyle = .fullScreen
        myAccountVC.rerenderProfileCallback = { } //no longer needed, since we update the accountButton on moveToSuperview
        self.navigationController?.present(myAccountNavigation, animated: true, completion: nil)
    }
    
}
                                           

//OverlayDelegate

extension FeedOverlayViewController {
    
    func handleFeedWentUp(duration: Double) {
        self.profilePicButton.isHidden = false
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            self.notchViewHeightConstraint.constant = 55
            self.notchView.applyLightBottomOnlyShadow()
            self.profilePicButton.alpha = 1
            self.notchView.layer.cornerRadius = 0
        } completion: { completed in
        }
    }
    
    func handleFeedWentDown(duration: Double) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            self.notchViewHeightConstraint.constant = 65
            self.notchView.applyMediumTopOnlyShadow()
            self.profilePicButton.alpha = 0
            self.notchView.layer.cornerRadius = 20
        } completion: { completed in
            self.profilePicButton.isHidden = true
        }
    }
}

//MARK: - TableViewDataSource

extension FeedOverlayViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.feed.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
        //in the feed, we don't need a reference to the postView like we do in
        let _ = cell.configurePostCell(post: posts[indexPath.row],
                               nestedPostViewDelegate: postDelegate,
                               bubbleTrianglePosition: .left,
                               isWithinPostVC: false)
        cell.contentView.backgroundColor = Constants.Color.offWhite
        return cell
    }
    
}

extension FeedOverlayViewController: UITableViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
}

//MARK: - Helper

extension FeedOverlayViewController {
    
//    func scrollFeedToPostRightAboveKeyboard(_ postIndex: Int) {
//        let postBottomYWithinFeed = feed.rectForRow(at: IndexPath(row: postIndex, section: 0))
//        let postBottomY = feed.convert(postBottomYWithinFeed, to: view).maxY
//        let keyboardTopY = view.bounds.height - keyboardHeight
//        let desiredOffset = postBottomY - keyboardTopY
//        if postIndex == 0 && desiredOffset < 0 { return } //dont scroll up for the very first post
//        feed.setContentOffset(feed.contentOffset.applying(.init(translationX: 0, y: desiredOffset)), animated: true)
//    }
}
