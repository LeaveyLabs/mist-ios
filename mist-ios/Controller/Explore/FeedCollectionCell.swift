//
//  FeedCollectionCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/10/13.
//

import Foundation

class FeedCollectionCell: UICollectionViewCell {
    
    var feedIndex: Int!
    var posts: [Post]!
    var postDelegate: PostDelegate!
    var exploreDelegate: ExploreChildDelegate!
    var contentOffsetYBeforeDragging: CGFloat = 0

    lazy var tableView: UITableView = {
          let tblView = UITableView()
          tblView.delegate = self
          tblView.dataSource = self
          tblView.translatesAutoresizingMaskIntoConstraints = false
          return tblView
    }()

     override init(frame: CGRect) {
         super.init(frame: frame)
         backgroundColor = Constants.Color.offWhite //UIColor.orange

         setupTableView()
     }
    
     func setupTableView() {
         addSubview(tableView)
         tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true //can't get these damn insets to work properly... just going to use this multiplier hack
         tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
         tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
         tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
         
         tableView.backgroundColor = Constants.Color.offWhite
         tableView.delegate = self
         tableView.dataSource = self
         tableView.estimatedRowHeight = 300
         tableView.rowHeight = UITableView.automaticDimension
         tableView.showsVerticalScrollIndicator = false
         tableView.separatorStyle = .none
         tableView.register(PostCell.self, forCellReuseIdentifier: Constants.SBID.Cell.Post)
         
         tableView.refreshControl = UIRefreshControl()
         tableView.refreshControl!.addTarget(self, action: #selector(pullToRefreshFeed), for: .valueChanged)
     }
    
    @objc func pullToRefreshFeed() {
        exploreDelegate.refreshFeedPosts()
    }

     required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
    
    func configure(postDelegate: PostDelegate,
                   exploreDelegate: ExploreChildDelegate,
                   posts: [Post],
                   position: Int) {
        self.feedIndex = position
        self.postDelegate = postDelegate
        self.exploreDelegate = exploreDelegate
        self.posts = posts
        
        tableView.contentInset = .init(top: self.frame.height * 0.15 + 14, left: 0, bottom: 100, right: 0)
        tableView.contentOffset = .init(x: 0, y: self.frame.height * -0.15 - 14) //i couldnt figure out how to make this insets proper under iphone8 - they were too high. so i just made the colleciton view extend higher than it should and upped hte insets here=
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.insetsLayoutMarginsFromSafeArea = false
        tableView.insetsContentViewsToSafeArea = false //must come after posts have been set
    }
    
}

extension FeedCollectionCell: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Post, for: indexPath) as! PostCell
        let _ = cell.configurePostCell(post: posts[indexPath.row],
                               nestedPostViewDelegate: postDelegate,
                               bubbleTrianglePosition: .left,
                               isWithinPostVC: false)
        cell.contentView.backgroundColor = Constants.Color.offWhite
        return cell
    }
    
}

//MARK: - TableViewDelegate

extension FeedCollectionCell: UITableViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        endEditing(true)
        resetContentOffsetY()
    }
    
    func resetContentOffsetY() {
        contentOffsetYBeforeDragging = tableView.contentOffset.y
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleHeaderOnScroll(scrollView)
        
        guard let greatestIndex = tableView.indexPathsForVisibleRows?.last?.row else { return }
        let postsUntilEnd = posts.count - greatestIndex
        guard postsUntilEnd == 50 else { return }
        exploreDelegate.loadNewFeedPostsIfNecessary()
    }
        
    func handleHeaderOnScroll(_ scrollView: UIScrollView) {
        let contentOffsetYDiff = contentOffsetYBeforeDragging - tableView.contentOffset.y
        if contentOffsetYDiff > 50 {
            exploreDelegate.toggleHeaderVisibility(visible: true)
        }
        if contentOffsetYDiff < -50 {
            exploreDelegate.toggleHeaderVisibility(visible: false)
        }
    }
    
}

//MARK: - Keyboard

extension FeedCollectionCell {
    
    func scrollFeedToPostRightAboveKeyboard(postIndex: Int, keyboardHeight: Double) {
        let postBottomYWithinFeed = tableView.rectForRow(at: IndexPath(row: postIndex, section: 0))
        let postBottomY = tableView.convert(postBottomYWithinFeed, to: self).maxY
        
        let keyboardTopY = tableView.bounds.height - keyboardHeight
        var desiredOffset = postBottomY - keyboardTopY
        
        desiredOffset -= 50 //for some reason i need to subtract 50 to my new implementation of this with the feed

        if postIndex == 0 && desiredOffset < 0 { return }  //dont scroll up for the very first post
        tableView.setContentOffset(tableView.contentOffset.applying(.init(translationX: 0, y: desiredOffset)), animated: true)
    }
    
}
