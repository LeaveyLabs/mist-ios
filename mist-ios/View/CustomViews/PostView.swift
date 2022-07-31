//
//  PostView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/04.
//

import UIKit
import MapKit

class ToggleButton: UIButton {
    var isSelectedImage: UIImage!
    var isSelectedTitle: String!
    var isNotSelectedImage: UIImage!
    var isNotSelectedTitle: String!
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                setImage(isSelectedImage, for: .normal)
                setTitle(isSelectedTitle, for: .normal)
            } else {
                setImage(isNotSelectedImage, for: .normal)
                setTitle(isNotSelectedTitle, for: .normal)
            }
        }
    }
}

class EmojiTextField: UITextField {
    
    // required for iOS 13
    override var textInputContextIdentifier: String? { "" } // return non-nil to show the Emoji keyboard ¯\_(ツ)_/¯

    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return nil
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
    
    @IBOutlet weak var dmButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var reactButton: UIButton! //ToggleButton!
    lazy var reactButtonTextField: EmojiTextField = {
        let emojiTextField = EmojiTextField(frame: .init(x: 1, y: 1, width: 1, height: 1))
        emojiTextField.isHidden = true
        emojiTextField.delegate = postDelegate
        self.addSubview(emojiTextField)
        return emojiTextField
    }()
    @IBOutlet weak var reactionsButton: UIButton!
//    @IBOutlet weak var likeLabelButton: UIButton! // We can't have the likeButton expand the whole stackview, and we also need a button in the rest of the stackview to prevent the post from being dismissed.
    
    @IBOutlet weak var fillerButton1: UIButton!
    @IBOutlet weak var fillerButton2: UIButton!
    @IBOutlet weak var fillerButton3: UIButton!
    @IBOutlet weak var fillerButton4: UIButton!
    @IBOutlet weak var fillerButton5: UIButton!

    //Data
    var postId: Int!
    var postAuthor: ReadOnlyUser!

    //Delegation
    var postDelegate: PostDelegate!
    
    //MARK: - Constructors
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customInit()
    }
    
    deinit {
        //Commenting this out for now
        //When you scroll through a bunch of posts, then posts get rendered and then derendered, and then you scroll back, you don't want to keep reloading those profile pics.
        //Ideally, we create a cache, but not worth the time right now on 6/25/22
//        postDelegate?.discardProfilePicTask(postId: postId)
    }
    
    private func customInit() {
        guard let contentView = loadViewFromNib(nibName: "PostView") else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        
//        reactButton.isSelectedTitle = ""
//        reactButton.isNotSelectedTitle = ""
//        reactButton.isSelectedImage = UIImage(systemName: "heart.fill")!
//        reactButton.isNotSelectedImage = UIImage(systemName: "heart")!
    }
        
    //MARK: - User Interaction
    
    // This action should be detected by a button, because the button will also prevent touches from
    // being passed through to the mapview
    @IBAction func backgroundButtonDidPressed(_ sender: UIButton) {
        postDelegate.handleBackgroundTap(postId: postId)
    }
    
    // The labelButton is actually just a button which we want to behave like the background.
//    @IBAction func likeLabelButtonDidPressed(_ sender: UIButton) {
//        postDelegate.handleBackgroundTap(postId: postId)
//    }
    
    @IBAction func commentButtonDidPressed(_ sender: UIButton) {
        postDelegate.handleCommentButtonTap(postId: postId)
    }
    
    @IBAction func dmButtonDidPressed(_ sender: UIButton) {
        if postAuthor.id == UserService.singleton.getId() {
            //do nothing
        } else {
            postDelegate.handleDmTap(postId: postId, author: postAuthor, dmButton: dmButton, title: postTitleLabel.text!)
        }
    }
    
    @IBAction func moreButtonDidPressed(_ sender: UIButton) {
        postDelegate.handleMoreTap(postId: postId, postAuthor: postAuthor.id)
    }

    @IBAction func reactButtonDidPressed(_ sender: UIButton) {
        reactButtonTextField.becomeFirstResponder()
    }
    
    func handleEmojiVote(emojiString: String) {
        //        // UI Updates
        //        reactButton.isEnabled = false
        //        reactButton.isSelected = !reactButton.isSelected
        //        if reactButton.isSelected {
        ////            likeLabelButton.setTitle(String(Int(likeLabelButton.titleLabel!.text!)! + 1), for: .normal)
        //        } else {
        ////            likeLabelButton.setTitle(String(Int(likeLabelButton.titleLabel!.text!)! - 1), for: .normal)
        //        }
        //
        //        // Remote and storage updates
        //        postDelegate.handleVote(postId: postId, isAdding: reactButton.isSelected)
        //        reactButton.isEnabled = true
    }
    
}

//MARK: - Public Interface

extension PostView {
    
    // Note: the constraints for the PostView should already be set-up when this is called.
    // Otherwise you'll get loads of constraint errors in the console
    func configurePost(post: Post, delegate: PostDelegate) {
        self.postId = post.id
        self.postAuthor = post.read_only_author
        self.postDelegate = delegate
        postDelegate.beginLoadingAuthorProfilePic(postId: postId, author: post.read_only_author)
        
        timestampLabel.text = getFormattedTimeString(timestamp: post.timestamp)
        locationLabel.text = post.location_description
        messageLabel.text = post.body
        postTitleLabel.text = post.title
//        likeLabelButton.setTitle(String(post.votecount), for: .normal)
        reactButton.isSelected = !VoteService.singleton.votesForPost(postId: post.id).isEmpty
        
        if post.author == UserService.singleton.getId() {
            dmButton.setTitleColor(.lightGray.withAlphaComponent(0.5), for: .normal)
            dmButton.imageView?.tintColor = .lightGray.withAlphaComponent(0.5)
        } else {
            dmButton.setTitleColor(.darkGray, for: .normal)
            dmButton.imageView?.tintColor = .darkGray
        }
        
        var arrowPosition: BubbleTrianglePosition!
        if let _ = superview as? PostAnnotationView {
            arrowPosition = .bottom
            if UIScreen.main.bounds.size.width < 350 {
                postTitleLabel.numberOfLines = 1
            }
        } else {
            arrowPosition = post.author == UserService.singleton.getId() ? .right : .left
        }
        backgroundBubbleView.transformIntoPostBubble(arrowPosition: arrowPosition)
        
        moreButton.transform = CGAffineTransform(rotationAngle: degreesToRadians(degrees: 90))
    }
    
    func reconfigurePost(updatedPost: Post) {
//        likeLabelButton.setTitle(String(updatedPost.votecount), for: .normal)
        reactButton.isSelected = !VoteService.singleton.votesForPost(postId: updatedPost.id).isEmpty
    }
    
    // We need to disable the backgroundButton and add a tapGestureRecognizer so that drags can be detected on the tableView. The purpose of the backgroundButton is to prevent taps from dismissing the calloutView when the post is within an annotation on the map
    func ensureTapsDontPreventScrolling() {
        backgroundBubbleButton.isUserInteractionEnabled = false
        fillerButton1.isUserInteractionEnabled = false
        fillerButton2.isUserInteractionEnabled = false
        fillerButton3.isUserInteractionEnabled = false
        fillerButton4.isUserInteractionEnabled = false
        fillerButton5.isUserInteractionEnabled = false

        backgroundBubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundButtonDidPressed(_:)) ))
    }
}
