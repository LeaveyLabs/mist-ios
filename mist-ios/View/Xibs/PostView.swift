//
//  PostView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/04.
//

import UIKit

@IBDesignable
class PostView: UIView {
    
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
    
    //MARK: - Initialization
        
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
    }
    
    //MARK: - User Interaction
    
    // This action should be detected by a button, because the button will also prevent touches from
    // being passed through to the mapview
    @IBAction func backgroundButtonDidPressed(_ sender: UIButton) {
        postDelegate?.backgroundDidTapped(post: post)
    }
    
    @IBAction func commentButtonDidPressed(_ sender: UIButton) {
        postDelegate?.commentDidTapped(post: post)
    }
    
    @IBAction func dmButtonDidPressed(_ sender: UIButton) {
        postDelegate?.dmDidTapped(post: post)
    }
    
    @IBAction func moreButtonDidPressed(_ sender: UIButton) {
        postDelegate?.moreDidTapped(post: post)
    }
    
    @IBAction func favoriteButtonDidpressed(_ sender: UIButton) {
        postDelegate?.favoriteDidTapped(post: post)
        
        // UI Updates
        favoriteButton.isSelected = !favoriteButton.isSelected
    }
    
    @IBAction func likeButtonDidPressed(_ sender: UIButton) {
        postDelegate?.likeDidTapped(post: post)
        
        // UI Updates
        let isAlreadyLiked = likeButton.isSelected
        if isAlreadyLiked {
            likeLabel.text = String(Int(likeLabel.text!)! - 1)
        } else {
            likeLabel.text = String(Int(likeLabel.text!)! + 1)
        }
        likeButton.isSelected = !likeButton.isSelected
    }
    
    @objc func myActionMethod(_ sender: UIGestureRecognizer) {
        print(sender)
        print("reached")
    }
    
}

//MARK: - Public Interface

extension PostView {
    
    func configurePost(post: Post, bubbleTrianglePosition: BubbleTrianglePosition) {
        self.post = post
        timestampLabel.text = getFormattedTimeString(postTimestamp: post.timestamp)
        locationLabel.text = post.location_description
        messageLabel.text = post.text
        titleLabel.text = post.title
        likeLabel.text = String(post.averagerating)
        likeButton.isSelected = false
        favoriteButton.isSelected = false

        addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(myActionMethod(_:))))
        backgroundBubbleView.transformIntoPostBubble(arrowPosition: bubbleTrianglePosition)
//        backgroundBubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self,
//                                                                         action: #selector(backgroundTapAction)))
    }
}

//extension PostView: UIGestureRecognizerDelegate {
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
//        return false
//    }
//}
