//
//  PostTableViewCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class PostCell: UITableViewCell {
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeLabel: UILabel!
    
    @IBOutlet weak var backgroundBubbleView: UIView!

    var postDelegate: PostDelegate?
    var post: Post!
    
    //MARK: - Public Interface
    
    func configurePostCell(post: Post, bubbleTrianglePosition: BubbleTrianglePosition) {
        self.post = post
        timestampLabel.text = getFormattedTimeString(postTimestamp: post.timestamp)
        locationLabel.text = post.location_description
        messageLabel.text = post.body
        titleLabel.text = post.title
        likeLabel.text = String(post.votecount)
        likeButton.isSelected = false
        favoriteButton.isSelected = false
        
        backgroundBubbleView.transformIntoPostBubble(arrowPosition: bubbleTrianglePosition)
        backgroundBubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                         action: #selector(backgroundTapAction)))
    }
    
    //MARK: - User Interaction
    
    @objc func backgroundTapAction() {
        postDelegate?.handleBackgroundTap(post: post)
    }
    
    @IBAction func commentButtonDidPressed(_ sender: UIButton) {
        postDelegate?.handleCommentButtonTap(post: post)
    }
    
    @IBAction func dmButtonDidPressed(_ sender: UIButton) {
        postDelegate?.handleDmTap(post: post)
    }
    
    @IBAction func moreButtonDidPressed(_ sender: UIButton) {
        postDelegate?.handleMoreTap(post: post)
    }
    
    @IBAction func favoriteButtonDidpressed(_ sender: UIButton) {
        
        // UI Updates
        favoriteButton.isSelected = !favoriteButton.isSelected
    }
    
    @IBAction func likeButtonDidPressed(_ sender: UIButton) {
        
        // UI Updates
        let isAlreadyLiked = likeButton.isSelected
        if isAlreadyLiked {
            likeLabel.text = String(Int(likeLabel.text!)! - 1)
        } else {
            likeLabel.text = String(Int(likeLabel.text!)! + 1)
        }
        likeButton.isSelected = !likeButton.isSelected
    }
    
}
