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
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var reactionsButton: UIButton!
    @IBOutlet weak var emojiButton1: EmojiButton!
    @IBOutlet weak var emojiButton2: EmojiButton!
    @IBOutlet weak var emojiButton3: EmojiButton!
    var emojiButtons: [EmojiButton] {
        get { return [emojiButton1, emojiButton2, emojiButton3] }
    }

    //Data
    var postId: Int!
    var authorId: Int!
    
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
    func configurePost(post: Post, delegate: PostDelegate, arrowPosition: BubbleTrianglePosition? = nil, updatedCommentCount: Int? = nil) {
        self.postId = post.id
        self.authorId = post.author
        self.postDelegate = delegate
        
        //if we are in PostViewController, make the body longer
        if postDelegate.isKind(of: PostViewController.self) {
            messageLabel.numberOfLines = 0
        }
        timestampLabel.text = getFormattedTimeStringForPost(timestamp: post.timestamp).lowercased()
        locationLabel.text = post.location_description?.lowercased()
        messageLabel.text = post.body
        postTitleLabel.text = post.title
        commentButton.setTitle(post.commentcount >= 3 ? String(updatedCommentCount ?? post.commentcount) : "comment", for: .normal)
        if post.author == UserService.singleton.getId() {
            dmButton.setTitleColor(.lightGray.withAlphaComponent(0.5), for: .normal)
            dmButton.imageView?.tintColor = .lightGray.withAlphaComponent(0.5)
        } else {
            dmButton.setTitleColor(.darkGray, for: .normal)
            dmButton.imageView?.tintColor = .darkGray
            dmButton.loadingIndicator(false) // just to be sure
        }
        
        backgroundBubbleView.transformIntoPostBubble(arrowPosition: arrowPosition ?? (post.author == UserService.singleton.getId() ? .right : .left))
        
        moreButton.transform = CGAffineTransform(rotationAngle: degreesToRadians(degrees: 90))
        
        //Whenever the user votes, we update the local copy of the post's emoji_dict
        //Whenever we display votes, we must sort through the dict to find the top three votes
        //This is especially important for superusers, because they could cast or remove a vote that was not originally in the topThreeVotes, and we want to be sure that the display of all emojis accurately reflects that
        //We keep greatest efficiency on the casting and removing of votes, but we lose some efficiency on the rendering of votes because we have to resort them each time
        let sortedEmojiVotes = post.emoji_dict.map( { ($0, $1) }).sorted(by: { $0.1 > $1.1 })
        setupEmojiButtons(topThreeVotes: Array(sortedEmojiVotes.prefix(3)))
    }
    
    func reconfigureVotes() {
        guard let emojiDict = PostService.singleton.getPost(withPostId: postId)?.emoji_dict else { return }
        let sortedEmojiVotes = emojiDict.map( { ($0, $1) }).sorted(by: { $0.1 > $1.1 })
        setupEmojiButtons(topThreeVotes: Array(sortedEmojiVotes.prefix(3)))
    }
    
}

extension PostView {
    
    //MARK: - Setup

    func setupEmojiButtons(topThreeVotes: [EmojiCountTuple]) {
        let usersCurrentVoteOnThisPost = VoteService.singleton.voteForPost(postId: postId)
        
        for index in (0 ..< topThreeVotes.count) {
            let emojiButton = emojiButtons[index]
            let topThreeVote = topThreeVotes[index]
            (emojiButton.emoji, emojiButton.count) = (topThreeVote.emoji, topThreeVote.count)
            emojiButton.isSelected = usersCurrentVoteOnThisPost != nil && usersCurrentVoteOnThisPost!.emoji == topThreeVote.emoji
        }
        
        if usersCurrentVoteOnThisPost != nil {
            ensureTheUsersVoteAppearsOnAButton()
        }
    }
    
    //If the user has voted, but it's not in the top three most popular votes, make it appear as the third vote
    func ensureTheUsersVoteAppearsOnAButton() {
        guard let usersVoteOnThisPost = VoteService.singleton.voteForPost(postId: postId) else { return }
        if !emojiButtons.contains(where: { $0.emoji == usersVoteOnThisPost.emoji }) {
            emojiButton3.isSelected = true
            guard
                let emojiDict = PostService.singleton.getPost(withPostId: postId)?.emoji_dict,
                let emojiCount = emojiDict[usersVoteOnThisPost.emoji]
            else { return }
            (emojiButton3.emoji, emojiButton3.count) = (usersVoteOnThisPost.emoji, emojiCount)
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
        if authorId == UserService.singleton.getId() {
            //do nothing
        } else {
            postDelegate.handleDmTap(postId: postId, authorId: authorId, dmButton: dmButton, title: postTitleLabel.text!)
        }
    }
    
    @IBAction func moreButtonDidPressed(_ sender: UIButton) {
        postDelegate.handleMoreTap(postId: postId, postAuthor: authorId)
    }

    @IBAction func reactButtonDidPressed(_ sender: UIButton) {
        if reactButtonTextField.isFirstResponder {
            reactButtonTextField.resignFirstResponder()
        } else {
            guard reactButtonTextField.isEmojiKeyboardEnabled else {
                CustomSwiftMessages.showInfoCentered("enable emoji keyboard", "turn on apple's default emoji keyboard in settings for custom reactions", emoji: "🫠")
                return
            }
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
    
    //not in use as of now
//    @objc func postWasDoubleTapped() {
//        guard
//            let random = Array(0x1F300...0x1F3F0).randomElement(),
//            let randomEmojiScalar = UnicodeScalar(random)
//        else { return }
//        let randomEmoji = String(randomEmojiScalar)
//        guard randomEmoji.isSingleEmoji else { return }
//        handleEmojiVote(emojiString: randomEmoji)
//    }
    
    @IBAction func emojiButtonDidPressed(_ sender: EmojiButton) {
        reactButtonTextField.resignFirstResponder()
        handleEmojiVote(emojiString: sender.emoji)
    }
        
    func handleEmojiVote(emojiString: String) {
        emojiButtons.forEach { $0.isEnabled = false }
        
        let hasUserAlreadyVoted = VoteService.singleton.voteForPost(postId: postId) != nil
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
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
//            self.resortEmojiButtonsByVoteCount() //this repositioning actually feels weird
            self.emojiButtons.forEach { $0.isEnabled = true }
        }
    }
    
    func resortEmojiButtonsByVoteCount() {
        if emojiButton2.count > emojiButton1.count {
            swapEmojiButtons(emojiButton1, emojiButton2)
        }
        //now we know that 1 and 2 are sorted properly
        if emojiButton3.count > emojiButton1.count {
            swapEmojiButtons(emojiButton3, emojiButton1)
            swapEmojiButtons(emojiButton3, emojiButton2)
        }  else if emojiButton3.count > emojiButton2.count {
            swapEmojiButtons(emojiButton1, emojiButton2)
        }
    }
    
    func swapEmojiButtons(_ buttonA: EmojiButton, _ buttonB: EmojiButton) {
        let Acount = buttonA.count
        let Aemoji = buttonA.emoji
        let AisSelected = buttonA.isSelected
        buttonA.count = buttonB.count
        buttonA.emoji = buttonB.emoji
        buttonA.isSelected = buttonB.isSelected
        buttonB.count = Acount
        buttonB.emoji = Aemoji
        buttonB.isSelected = AisSelected
    }
    
}

//MARK: - Vote Helpers

extension PostView {
    
    //on any given post that we've loaded load in, here are the potential states:
    //no vote, and no change
    //no vote, and we added one
    //was vote, and no change
    //was vote, and we changed it
    //was vote, and we removed it
    
    func deleteVote(_ emojiString: String) {
        print("DELETE VOTE")
        guard let existingVoteRating = VoteService.singleton.voteForPost(postId: postId)?.rating else { return }
        guard let selectedEmojiButton = emojiButtons.first(where: { $0.isSelected }) else { return }
        selectedEmojiButton.isSelected = false
        selectedEmojiButton.count -= existingVoteRating
        
        //remote and stoarge updates
        postDelegate.handleVote(postId: postId, emoji: emojiString, emojiBeforePatch: nil, existingVoteRating: existingVoteRating, action: .delete)
    }
    
    //They have already voted, and they're changing their vote to one of the other two already on the screen
    func patchVoteWithExistingEmoji(_ emojiString: String) {
        print("PATCH VOTE EXISTING")
        guard let existingVoteRating = VoteService.singleton.voteForPost(postId: postId)?.rating else { return }
        guard let previouslySelectedEmojiButton = emojiButtons.first(where: { $0.isSelected }) else { return }
        guard let newlySelectedEmojiButton = emojiButtons.first(where: { $0.emoji == emojiString }) else { return }
        previouslySelectedEmojiButton.isSelected = false
        previouslySelectedEmojiButton.count -= existingVoteRating
        newlySelectedEmojiButton.isSelected = true
        newlySelectedEmojiButton.count += VoteService.singleton.getCastingVoteRating()
        
        //remote and storage updates
        postDelegate.handleVote(postId: postId, emoji: emojiString, emojiBeforePatch: previouslySelectedEmojiButton.emoji, existingVoteRating: existingVoteRating, action: .patch)
    }
    
    //They have already voted, and they're changing their vote to a custom emoji
    func patchVoteWithCustomEmoji(_ emojiString: String) {
        print("PATCH VOTE CUSTOM")
        guard let existingVoteRating = VoteService.singleton.voteForPost(postId: postId)?.rating else { return }
        guard let previouslySelectedEmojiButton = emojiButtons.first(where: { $0.isSelected }) else { return }
        let previousEmoji = previouslySelectedEmojiButton.emoji //we need to hold onto this button's emoji in case it was actually button3, meaning it would get overrided below
        previouslySelectedEmojiButton.count -= existingVoteRating
        previouslySelectedEmojiButton.isSelected = false
        
        //see if the emoji already has some votes
        let customVote: EmojiCountTuple
        guard let emojiDict = PostService.singleton.getPost(withPostId: postId)?.emoji_dict else { return }
        if let existingVoteCountForSameEmoji = emojiDict[emojiString] {
            customVote = EmojiCountTuple(emojiString, existingVoteCountForSameEmoji + VoteService.singleton.getCastingVoteRating())
        } else {
            customVote = EmojiCountTuple(emojiString, VoteService.singleton.getCastingVoteRating())
        }
        (emojiButton3.emoji, emojiButton3.count) = (customVote.emoji, customVote.count)
        emojiButton3.isSelected = true

        //remote and storage updates
        postDelegate.handleVote(postId: postId, emoji: emojiString, emojiBeforePatch: previousEmoji, existingVoteRating: existingVoteRating, action: .patch)
    }
    
    //They're adding a vote to one of the three already on the screen
    func castVoteWithExistingEmoji(_ emojiString: String) {
        print("CAST VOTE EXISTING")
        guard let newlySelectedEmojiButton = emojiButtons.first(where: { $0.emoji == emojiString }) else { return }
        newlySelectedEmojiButton.count += VoteService.singleton.getCastingVoteRating()
        newlySelectedEmojiButton.isSelected = true

        //remote and storage updates
        postDelegate.handleVote(postId: postId, emoji: emojiString, emojiBeforePatch: nil, existingVoteRating: nil, action: .cast)
    }
    
    func castVoteWithCustomEmoji(_ emojiString: String) {
        print("CAST VOTE CUSTOM")
        guard let emojiDict = PostService.singleton.getPost(withPostId: postId)?.emoji_dict else { return }
        let previousVoteCountForThisEmoji = emojiDict[emojiString] ?? 0
        (emojiButton3.emoji, emojiButton3.count) = (emojiString, previousVoteCountForThisEmoji + VoteService.singleton.getCastingVoteRating())
        emojiButton3.isSelected = true //The third button always has the least votes

        //remote and storage updates
        postDelegate.handleVote(postId: postId, emoji: emojiString, emojiBeforePatch: nil, existingVoteRating: nil, action: .cast)
    }
    
}
