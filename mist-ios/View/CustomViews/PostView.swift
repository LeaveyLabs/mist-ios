//
//  PostView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/04.
//

import UIKit
import MapKit

class PostButton: UIButton {
    var isSelectedImage: UIImage!
    var isNotSelectedImage: UIImage!
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                setImage(isSelectedImage, for: .normal)
            } else {
                setImage(isNotSelectedImage, for: .normal)
            }
        }
    }
}

@IBDesignable class PostView: SpringView {
        
    //MARK: - Properties
    
    //UI
    @IBOutlet weak var backgroundBubbleButton: UIButton! //in an ideal world we would only use the bubbleButton and not the bubbleView. But alas, you cannot add subviews to uibutton in xibs, yet we need to have the background be a button
    
    @IBOutlet weak var backgroundBubbleView: UIView!
    // Note: When rendered as a callout of PostAnnotationView, in order to prevent touches from being detected on the map, there is a background button which sits at the very back of backgroundBubbleView, with an IBAction hooked up to it. Each view on top of it must either have user interaction disabled so the touches pass back to the button, or they should be a button themselves. Stack views with spacing >0 whose user interaction is enabled will also create undesired behavior where a tap will dismiss the post
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var postTitleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var favoriteButton: PostButton!
    @IBOutlet weak var likeButton: PostButton!
    @IBOutlet weak var likeLabelButton: UIButton! // We can't have the likeButton expand the whole stackview, and we also need a button in the rest of the stackview to prevent the post from being dismissed.
    
    //Data
    var postId: Int!
    var authorId: Int!

    //Delegation
    var postDelegate: PostDelegate?
    
    //MARK: - Constructors
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customInit()
    }
    
    private func customInit() {
        guard let contentView = loadViewFromNib(nibName: "PostView") else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        
        favoriteButton.isSelectedImage = UIImage(systemName: "bookmark.fill")!
        favoriteButton.isNotSelectedImage = UIImage(systemName: "bookmark")!
        likeButton.isSelectedImage = UIImage(systemName: "heart.fill")!
        likeButton.isNotSelectedImage = UIImage(systemName: "heart")!
    }
        
    //MARK: - User Interaction
    
    // This action should be detected by a button, because the button will also prevent touches from
    // being passed through to the mapview
    @IBAction func backgroundButtonDidPressed(_ sender: UIButton) {
        postDelegate?.handleBackgroundTap(postId: postId)
    }
    
    // The labelButton is actually just a button which we want to behave like the background.
    @IBAction func likeLabelButtonDidPressed(_ sender: UIButton) {
        postDelegate?.handleBackgroundTap(postId: postId)
    }
    
    @IBAction func commentButtonDidPressed(_ sender: UIButton) {
        postDelegate?.handleCommentButtonTap(postId: postId)
    }
    
    @IBAction func dmButtonDidPressed(_ sender: UIButton) {
        postDelegate?.handleDmTap(postId: postId, authorId: authorId)
    }
    
    @IBAction func moreButtonDidPressed(_ sender: UIButton) {
        postDelegate?.handleMoreTap()
    }
    
    @IBAction func favoriteButtonDidpressed(_ sender: UIButton) {
        // UI Updates
        favoriteButton.isEnabled = false
        favoriteButton.isSelected = !favoriteButton.isSelected
        
        // Remote and storage updates
        postDelegate?.handleFavorite(postId: postId, isAdding: favoriteButton.isSelected)
        favoriteButton.isEnabled = true
    }
    
    @IBAction func likeButtonDidPressed(_ sender: UIButton) {
        // UI Updates
        likeButton.isEnabled = false
        likeButton.isSelected = !likeButton.isSelected
        if likeButton.isSelected {
            likeLabelButton.setTitle(String(Int(likeLabelButton.titleLabel!.text!)! + 1), for: .normal)
        } else {
            likeLabelButton.setTitle(String(Int(likeLabelButton.titleLabel!.text!)! - 1), for: .normal)
        }
        
        // Remote and storage updates
        postDelegate?.handleVote(postId: postId, isAdding: likeButton.isSelected)
        likeButton.isEnabled = true
    }
    
}

//MARK: - Public Interface

extension PostView {
    
    // Note: the constraints for the PostView should already be set-up when this is called.
    // Otherwise you'll get loads of constraint errors in the console
    func configurePost(post: Post) {
        self.postId = post.id
        self.authorId = post.author
        timestampLabel.text = getFormattedTimeString(timestamp: post.timestamp)
        locationLabel.text = post.location_description
        messageLabel.text = post.body
        postTitleLabel.text = post.title
        likeLabelButton.setTitle(String(post.votecount), for: .normal)
        likeButton.isSelected = !VoteService.singleton.votesForPost(postId: post.id).isEmpty
        favoriteButton.isSelected = FavoriteService.singleton.hasFavoritedPost(postId)
        
        var arrowPosition: BubbleTrianglePosition!
        if let _ = superview as? PostAnnotationView {
            arrowPosition = .bottom
        } else {
            arrowPosition = post.author == UserService.singleton.getId() ? .right : .left
        }
        backgroundBubbleView.transformIntoPostBubble(arrowPosition: arrowPosition)
    }
    
    func reconfigurePost(updatedPost: Post) {
        likeLabelButton.setTitle(String(updatedPost.votecount), for: .normal)
        likeButton.isSelected = !VoteService.singleton.votesForPost(postId: updatedPost.id).isEmpty
        favoriteButton.isSelected = FavoriteService.singleton.hasFavoritedPost(updatedPost.id)
    }
    
}
