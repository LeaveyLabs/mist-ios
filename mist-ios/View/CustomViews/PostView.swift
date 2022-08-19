//
//  PostView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/04.
//

import UIKit
import MapKit

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
        let emojiTextField = EmojiTextField(frame: .init(x: 1, y: backgroundBubbleView.frame.maxY - reactButton.frame.height, width: 10, height: 1)) //position the emojiTextField at the bottom of an emoji Button. This prevents an error which existed where the emojiKeyboard raising wouldn't actually scroll for super long posts. Note: Can't put it all the way down at the bottom of postView, because with the hidden inputBar on PostViewController resting on top of the emoji keyboard, the hidden input bar ends up "covering" the emojiTextField and iOS autocorrects the keyboard in a way we don't want
//        emojiTextField.backgroundColor = .red
        emojiTextField.isHidden = true
        emojiTextField.delegate = postDelegate
        emojiTextField.postDelegate = postDelegate
        self.addSubview(emojiTextField)
        return emojiTextField
    }()
    @IBOutlet weak var reactionsButton: UIButton!
    @IBOutlet weak var emojiButton1: EmojiButton!
    @IBOutlet weak var emojiButton2: EmojiButton!
    @IBOutlet weak var emojiButton3: EmojiButton!
    var emojiButtons: [EmojiButton] {
        get { return [emojiButton1, emojiButton2, emojiButton3] }
    }
    
    @IBOutlet weak var fillerButton1: UIButton!
    @IBOutlet weak var fillerButton2: UIButton!
    @IBOutlet weak var fillerButton3: UIButton!
    @IBOutlet weak var fillerButton4: UIButton!
    @IBOutlet weak var fillerButton5: UIButton!

    //Data
    var postId: Int!
    var postAuthor: ReadOnlyUser!
    var postEmojiCountTuples: [EmojiCountTuple]!
    var usersVoteBeforePostWasLoaded: PostVote?
    
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
        
        //if we are in PostViewController, make the body longer
        if postDelegate.isKind(of: PostViewController.self) {
            messageLabel.numberOfLines = 0
        }
        timestampLabel.text = getFormattedTimeString(timestamp: post.timestamp)
        locationLabel.text = post.location_description
        messageLabel.text = post.body
        postTitleLabel.text = post.title
        
        if post.author == UserService.singleton.getId() {
            dmButton.setTitleColor(.lightGray.withAlphaComponent(0.5), for: .normal)
            dmButton.imageView?.tintColor = .lightGray.withAlphaComponent(0.5)
        } else {
            dmButton.setTitleColor(.darkGray, for: .normal)
            dmButton.imageView?.tintColor = .darkGray
            dmButton.loadingIndicator(false) // just to be sure
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
        
        self.usersVoteBeforePostWasLoaded = post.votes.first {$0.voter == UserService.singleton.getId() }
        self.postEmojiCountTuples = post.emojiCountTuples
        setupEmojiButtons(topThreeVotes: Array(self.postEmojiCountTuples.prefix(3)))
    }
    
    func reconfigurePost(updatedPost: Post) {
        setupEmojiButtons(topThreeVotes: Array(self.postEmojiCountTuples.prefix(3)))
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


extension PostView {
    
    //MARK: - Setup
        
    //How the emojiButton.count adjustment works:
    //Whenever the user refreshes posts, we load in posts and votes
    //Whenever the user reacts with a post, we update the votes in VoteService, but we do NOT update the votes on the post object itself
    //We know if the emojiButton.count needs to be adjusted if the VoteService and post's votes are out of sync: it means that the user added or removed a vote since the last post load.
    
    //on any given post that we've loaded load in, here are the potential states:
    //no vote, and no change
    //no vote, and we added one
    //was vote, and no change
    //was vote, and we changed it
    //was vote, and we removed it
    
    func setupEmojiButtons(topThreeVotes: [EmojiCountTuple]) {
        let usersCurrentVoteOnThisPost = VoteService.singleton.votesForPost(postId: postId).first
        
        for index in (0 ..< topThreeVotes.count) {
            let emojiButton = emojiButtons[index]
            let topThreeVote = topThreeVotes[index]
            (emojiButton.emoji, emojiButton.count) = (topThreeVote.emoji, topThreeVote.count)
            if let usersCurrentVoteOnThisPost = usersCurrentVoteOnThisPost {
                emojiButton.isSelected = usersCurrentVoteOnThisPost.emoji == topThreeVote.emoji
                
                //user had no original vote, but they added one
                if usersVoteBeforePostWasLoaded == nil &&
                    usersCurrentVoteOnThisPost.emoji == topThreeVote.emoji {
                    emojiButton.count += 1
                }
                
                //user had an original vote, but they changed it
                if let usersVoteBeforePostWasLoaded = usersVoteBeforePostWasLoaded,
                   usersVoteBeforePostWasLoaded.emoji != usersCurrentVoteOnThisPost.emoji {
                    //if this is their new vote, then increment it
                    if usersCurrentVoteOnThisPost.emoji == topThreeVote.emoji {
                        emojiButton.count += 1
                    }
                    //if this is their old vote, then decrement it
                    if usersVoteBeforePostWasLoaded.emoji == topThreeVote.emoji {
                        emojiButton.count -= 1
                    }
                }
            } else {
                emojiButton.isSelected = false //deselect all buttons just in case
                
                //user had an original vote, but they remove it
                if let usersVoteBeforePostWasLoaded = usersVoteBeforePostWasLoaded,
                   usersVoteBeforePostWasLoaded.emoji == topThreeVote.emoji {
                    emojiButton.count -= 1
                }
            }
        }
        
        if usersCurrentVoteOnThisPost != nil {
            ensureTheUsersVoteAppearsOnAButton()
        }
    }
    
    func ensureTheUsersVoteAppearsOnAButton() {
        guard let usersVoteOnThisPost = VoteService.singleton.votesForPost(postId: postId).first else { return }
        if !emojiButtons.contains(where: { $0.emoji == usersVoteOnThisPost.emoji }) {
            //Make emojiButton3 the emoji of the user's vote on this post
            
            emojiButton3.isSelected = true
            if let votedOriginalTuple = postEmojiCountTuples.first(where: {$0.emoji == usersVoteOnThisPost.emoji }) {
                (emojiButton3.emoji, emojiButton3.count) = (usersVoteOnThisPost.emoji,
                                                            votedOriginalTuple.count)
            } else {
                (emojiButton3.emoji, emojiButton3.count) = (usersVoteOnThisPost.emoji,
                                                            0)
            }
            //COUNT INCREMENT HANDLING
            //case 1: user had no original vote, so they must have added this one
            if usersVoteBeforePostWasLoaded == nil  {
                emojiButton3.count += 1
            }
            //case 2: user had an original vote when posts were loaded in, but they changed it
            if let usersVoteBeforePostWasLoaded = usersVoteBeforePostWasLoaded,
               usersVoteBeforePostWasLoaded.emoji != usersVoteOnThisPost.emoji {
                emojiButton3.count += 1
            }
        }
    }
        
    //MARK: - User Interaction
    
    // This action should be detected by a button, because the button will also prevent touches from being passed through to the mapview
    @IBAction func backgroundButtonDidPressed(_ sender: UIButton) {
        postDelegate.handleBackgroundTap(postId: postId)
    }
    
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
        if reactButtonTextField.isFirstResponder {
            reactButtonTextField.resignFirstResponder()
        } else {
            if let postVC = postDelegate as? PostViewController, postVC.inputBar.inputTextView.isFirstResponder {
                postVC.inputBar.inputTextView.resignFirstResponder()
                postDelegate.handleReactTap(postId: postId) //must come first to set flags
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { //let the other keyboard dismiss
                    self.reactButtonTextField.becomeFirstResponder()
                }
            } else {
                postDelegate.handleReactTap(postId: postId) //must come first to set flags
                reactButtonTextField.becomeFirstResponder()
            }
        }
    }
    
    @IBAction func emojiButtonDidPressed(_ sender: EmojiButton) {
        handleEmojiVote(emojiString: sender.emoji)
    }
        
    func handleEmojiVote(emojiString: String) {
        emojiButtons.forEach { $0.isEnabled = false }
        
        let hasUserAlreadyVoted = !VoteService.singleton.votesForPost(postId: postId).isEmpty
        let doesNewEmojiAlreadyExist = emojiButtons.firstIndex { $0.emoji == emojiString } != nil
        let isUserDeletingTheirVote = emojiButtons.firstIndex { $0.isSelected && $0.emoji == emojiString } != nil

        if hasUserAlreadyVoted {
            if isUserDeletingTheirVote {
                deleteVote(emojiString)
            } else {
                if doesNewEmojiAlreadyExist {
                    patchVoteWithExistingEmoji(emojiString)
                } else {
                    patchVoteWithCustomEmoji(emojiString)
                }
            }
        } else {
            if doesNewEmojiAlreadyExist {
                castVoteWithExistingEmoji(emojiString)
            } else {
                castVoteWithCustomEmoji(emojiString)
            }
        }

        emojiButtons.forEach { $0.isEnabled = true }
    }
    
}

//MARK: - Vote Helpers

extension PostView {
    
    func deleteVote(_ emojiString: String) {
        print("DELETE VOTE")
        guard let selectedEmojiButton = emojiButtons.first(where: { $0.isSelected }) else { return }
        selectedEmojiButton.isSelected = false
        selectedEmojiButton.count -= 1
        
        //remote and stoarge updates
        postDelegate.handleVote(postId: postId, emoji: emojiString, action: .delete)
    }
    
    //They have already voted, and they're changing their vote to one of the other two already on the screen
    func patchVoteWithExistingEmoji(_ emojiString: String) {
        print("PATCH VOTE EXISTING")
        guard let previouslySelectedEmojiButton = emojiButtons.first(where: { $0.isSelected }) else { return }
        guard let newlySelectedEmojiButton = emojiButtons.first(where: { $0.emoji == emojiString }) else { return }
        previouslySelectedEmojiButton.isSelected = false
        previouslySelectedEmojiButton.count -= 1
        newlySelectedEmojiButton.isSelected = true
        newlySelectedEmojiButton.count += 1
        
        //remote and storage updates
        postDelegate.handleVote(postId: postId, emoji: emojiString, action: .patch)
    }
    
    //They have already voted, and they're changing their vote to a custom emoji
    func patchVoteWithCustomEmoji(_ emojiString: String) {
        print("PATCH VOTE CUSTOM")
        guard let previouslySelectedEmojiButton = emojiButtons.first(where: { $0.isSelected }) else { return }
        previouslySelectedEmojiButton.count -= 1
        previouslySelectedEmojiButton.isSelected = false
        
        //see if the emoji already has some votes
        let customVote: EmojiCountTuple
        if let existingVoteWithSameEmoji = postEmojiCountTuples.first(where: { $0.emoji == emojiString }) {
            customVote = EmojiCountTuple(emojiString, existingVoteWithSameEmoji.count + 1)
        } else {
            customVote = EmojiCountTuple(emojiString, 1)
        }
        
        (emojiButton3.emoji, emojiButton3.count) = (customVote.emoji, customVote.count)
        emojiButton3.isSelected = true

        //the ordering won't be PERFECT this way. If we want perfect sequential ordering, we would need to re-run the code that we use on emojisButtonsSetup with all the special checks for a decrement or increment on the other buttons, and then putting our new button in at the right spot
        
        //reset all the buttons with the proper ordering
//        var isCustomVoteAvailable = true
//        for index in (0 ..< 3) {
//            //put your customVote at button1/2 if its count is high enough, otherwise at button3
//            if (customVote.count >= postEmojiCountTuples[index].count || index == 2) && isCustomVoteAvailable {
//                isCustomVoteAvailable = false
//                (emojiButtons[index].emoji, emojiButtons[index].count) = (customVote.emoji, customVote.count)
//                emojiButtons[index].isSelected = true
//            } else {
//                (emojiButtons[index].emoji, emojiButtons[index].count) = (postEmojiCountTuples[index].emoji, postEmojiCountTuples[index].count)
//                //We need to decrement the count again here since its corresponding emojiCountTuple.count is now out of data. We don't HAVE to decrement the count at the start of patchVoteWithCustomEmoji(), but it will make this calculation slightly more accurate
//                if postEmojiCountTuples[index].emoji == previouslySelectedEmojiButton.emoji {
//                    emojiButtons[index].count -= 1
//                }
//            }
//        }

        //remote and storage updates
        postDelegate.handleVote(postId: postId, emoji: emojiString, action: .patch)
    }
    
    //They're adding a vote to one of the three already on the screen
    func castVoteWithExistingEmoji(_ emojiString: String) {
        print("CAST VOTE EXISTING")
        guard let newlySelectedEmojiButton = emojiButtons.first(where: { $0.emoji == emojiString }) else { return }
        newlySelectedEmojiButton.count += 1
        newlySelectedEmojiButton.isSelected = true

        //remote and storage updates
        postDelegate.handleVote(postId: postId, emoji: emojiString, action: .cast)
    }
    
    func castVoteWithCustomEmoji(_ emojiString: String) {
        print("CAST VOTE CUSTOM")
        let previousVoteCountForThisEmoji = postEmojiCountTuples.first { $0.emoji == emojiString }?.count ?? 0
        (emojiButton3.emoji, emojiButton3.count) = (emojiString, previousVoteCountForThisEmoji + 1)
        emojiButton3.isSelected = true //The third button always has the least votes

        //remote and storage updates
        postDelegate.handleVote(postId: postId, emoji: emojiString, action: .cast)
    }
    
}
