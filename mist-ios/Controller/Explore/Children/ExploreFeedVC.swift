//
//  FeedOverlayViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/30/22.
//

import Foundation
import UIKit

//MARK: - Table View Setup

class ExploreFeedViewController: UIViewController {
        
    //Delegate
    var postDelegate: PostDelegate!
    var exploreDelegate: ExploreChildDelegate!
    
    //UI
    @IBOutlet weak var feed: PostTableView!
    @IBOutlet weak var notchHandleView: UIView!
    @IBOutlet weak var notchView: UIView!
    @IBOutlet weak var notchViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var notchTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var navStackView: UIStackView!
    
    class func create(postDelegate: PostDelegate, exploreDelegate: ExploreChildDelegate) -> ExploreFeedViewController {
        let feedOverlay = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.ExploreFeed) as! ExploreFeedViewController
        feedOverlay.postDelegate = postDelegate
        feedOverlay.exploreDelegate = exploreDelegate
        return feedOverlay
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotchView()
        setupTableView()
        view.backgroundColor = .clear
        filterButton.alpha = 0
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
        feed.refreshControl = UIRefreshControl()
        feed.refreshControl!.addTarget(self, action: #selector(pullToRefreshFeed), for: .valueChanged)
    }
    
    @objc func pullToRefreshFeed() {
        PostService.singleton.updateFilter(newPostSort: PostService.singleton.getExploreFilter().postSort)
        exploreDelegate.handleUpdatedExploreFilter()
    }
    
    //MARK: - UserInteraction
    
    @IBAction func filterButtonDidPressed() {
        guard let parent = exploreDelegate as? HomeExploreParentViewController else { return }
        let filterVC = FeedFilterSheetViewController.create(delegate: parent)
        present(filterVC, animated: true)
    }
    
    @IBAction func refreshButtonDidPressed() {
        guard let parent = exploreDelegate as? CustomExploreParentViewController else { return }
        refreshCustomExplorePosts(setting: parent.setting)
    }
    
    func refreshCustomExplorePosts(setting: Setting) {
        refreshButton.isUserInteractionEnabled = false
        refreshButton.loadingIndicator(true)
        refreshButton.setImage(nil, for: .normal)
        Task {
            do {
                switch setting {
                case .mentions:
                    try await PostService.singleton.loadMentions()
                case .submissions:
                    try await PostService.singleton.loadSubmissions()
                case .favorites:
                    try await FavoriteService.singleton.loadFavorites() //also loads in favorites
                default:
                    break
                }
                DispatchQueue.main.async { [weak self] in
                    self?.exploreDelegate.renderNewPostsOnFeed(withType: .newSearch) //to reposition
                    self?.exploreDelegate.renderNewPostsOnMap(withType: .newSearch)
                    self?.refreshButton.isUserInteractionEnabled = true
                    self?.refreshButton.loadingIndicator(false)
                    self?.refreshButton.setImage(UIImage(systemName: "arrow.clockwise", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))!, for: .normal)
                }
            } catch {
                CustomSwiftMessages.displayError(error)
                DispatchQueue.main.async { [weak self] in
                    self?.refreshButton.isUserInteractionEnabled = true
                    self?.refreshButton.loadingIndicator(false)
                    self?.refreshButton.setImage(UIImage(systemName: "arrow.clockwise", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))!, for: .normal)
                }
            }
        }
    }

}
                                           

//MARK: - ParentOverlayDelegate

extension ExploreFeedViewController {
    
    func handleFeedWentUp(duration: Double) {
//        refreshButton.layer.removeAllAnimations()
//        filterButton.layer.removeAllAnimations()
        notchView.layer.removeAllAnimations()
//        self.refreshButton.isHidden = false
//        self.filterButton.isHidden = false
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            self.notchViewHeightConstraint.constant = 55
            self.notchView.applyLightBottomOnlyShadow()
            self.filterButton.alpha = 1
//            self.refreshButton.alpha = 1
//            self.filterButton.alpha = 1
            self.notchView.layer.cornerRadius = 0
            
            if let _ = self.exploreDelegate as? HomeExploreParentViewController { //otherwise it cuts off the title
                self.notchTopConstraint.constant = 12
            }
            self.view.layoutIfNeeded()
        } completion: { completed in
        }
    }
    
    func handleFeedWentSlightlyDown(duration: Double) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            self.notchViewHeightConstraint.constant = 65
            self.notchView.layer.cornerRadius = 20
            self.notchTopConstraint.constant = 5
            self.view.layoutIfNeeded()
        }
    }
    
    func handleFeedWentDown(duration: Double) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear) {
            self.notchViewHeightConstraint.constant = 65
            self.notchView.applyMediumTopOnlyShadow()
            self.filterButton.alpha = 0
//            self.refreshButton.alpha = 0
//            self.filterButton.alpha = 0
            self.notchView.layer.cornerRadius = 20
            self.notchTopConstraint.constant = 5
            self.view.layoutIfNeeded()
        } completion: { completed in
//            self.filterButton.isHidden = true
//            self.refreshButton.isHidden = true
        }
    }
}

//MARK: - TableViewDataSource

extension ExploreFeedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exploreDelegate.feedPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.feed.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
        let cachedPost = PostService.singleton.getPost(withPostId: exploreDelegate.feedPosts[indexPath.row].id)!
        let _ = cell.configurePostCell(post: cachedPost,
                               nestedPostViewDelegate: postDelegate,
                               bubbleTrianglePosition: .left,
                               isWithinPostVC: false)
        cell.contentView.backgroundColor = Constants.Color.offWhite
        return cell
    }
    
}

extension ExploreFeedViewController: UITableViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let greatestIndex = feed.indexPathsForVisibleRows?.last?.row else { return }
        let postsUntilEnd = PostService.singleton.getExploreFeedPostsSortedIds().count - greatestIndex
        guard postsUntilEnd == 50 else { return }
        exploreDelegate.reloadNewFeedPostsIfNecessary()
    }
    
}

//MARK: - Keyboard

extension ExploreFeedViewController {
    
    func scrollFeedToPostRightAboveKeyboard(postIndex: Int, keyboardHeight: Double) {
        let postBottomYWithinFeed = feed.rectForRow(at: IndexPath(row: postIndex, section: 0))
        let postBottomY = feed.convert(postBottomYWithinFeed, to: view).maxY
        
        let keyboardTopY = view.bounds.height - keyboardHeight
        var desiredOffset = postBottomY - keyboardTopY
        if postIndex == 0 && desiredOffset < 0 { return } //dont scroll up for the very first post
        desiredOffset -= 100 //for some reason i need to add 50 to my new implementation of this with the feed
        feed.setContentOffset(feed.contentOffset.applying(.init(translationX: 0, y: desiredOffset)), animated: true)
    }
    
}
