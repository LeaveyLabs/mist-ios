//
//  CommentCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

extension UIView {
    func becomeCommentView() {
        applyLightLeftShadow()
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous
    }
}

class CommentCell: UITableViewCell {
    
    //MARK: - Properties

    //UI
    @IBOutlet weak var authorUsernameButton: UIButton!
    @IBOutlet weak var authorProfilePicButton: UIButton!
//    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var commentTextView: LinkTextView!
//    @IBOutlet weak var backgroundBubbleView: UIView!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var bottomDividerView: UIView!
    
    @IBOutlet weak var voteButton: ToggleButton!
    @IBOutlet weak var voteLabelButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    
    //Information
    var comment: Comment!
    var author: FrontendReadOnlyUser!
    
    //Delegate
    var commentDelegate: CommentDelegate!

    
    //MARK: - Initializer
    
    func configureCommentCell(comment: Comment, delegate: CommentDelegate, author: FrontendReadOnlyUser, shouldHideDivider: Bool) {
        self.comment = comment
        self.commentDelegate = delegate
        self.author = author
        bottomDividerView.isHidden = true //shouldHideDivider
        timestampLabel.text = getShortFormattedTimeString(timestamp: comment.timestamp)
        authorUsernameButton.setTitle(author.username, for: .normal)
        UIView.performWithoutAnimation {
            authorProfilePicButton.imageView?.becomeProfilePicImageView(with: author.thumbnailPic)
        }
        setupCommentTextView(text: comment.body, tags: comment.tags, delegate: delegate)
//        if (comment.id == 249) {
//            print("votecount", comment.votecount)
//        }
        setupVoteButton(comment.votecount)
        authorUsernameButton.setImage(nil, for: .normal)
        
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressComment))
        self.addGestureRecognizer(longTap)
        let swipeLeftGesture = PanDirectionGestureRecognizer(axis: .horizontal, direction: .left, target: self, action: #selector(didLongPressComment))
        self.addGestureRecognizer(swipeLeftGesture)
    }
    
    func setupVoteButton(_ votecount: Int) {
        voteButton.selectedTintColor = Constants.Color.mistLilac
        voteButton.notSelectedTintColor = .lightGray
        voteButton.notSelectedTitle = ""
        voteButton.selectedTitle = ""
        voteButton.selectedImage = UIImage(systemName: "heart.fill")
        voteButton.notSelectedImage = UIImage(systemName: "heart")
        voteLabelButton.setTitleColor(Constants.Color.mistLilac, for: .selected)
        voteLabelButton.setTitleColor(.lightGray, for: .normal)
        
        let didLikeThisComment = VoteService.singleton.voteForComment(commentId: comment.id) != nil
        
        voteLabelButton.setTitle(votecount == 0 ? "" : String(didLikeThisComment ? votecount - 1 : votecount), for: .normal)
        voteLabelButton.setTitle(votecount == 0 ? "1" : String(didLikeThisComment ? votecount : votecount + 1), for: .selected)
        voteButton.isSelected = didLikeThisComment
        voteLabelButton.isSelected = didLikeThisComment
    }
    
    func setupCommentTextView(text: String, tags: [Tag], delegate: CommentDelegate) {
        commentTextView.text = comment.body
        commentTextView.delegate = delegate
        
        var links: LinkTextView.Links = .init()
        for tag in tags {
            guard let _ = text.range(of: tag.tagged_name) else { return }
            delegate.beginLoadingTaggedProfile(taggedUserId: tag.tagged_user, taggedNumber: tag.tagged_phone_number) //one of the parameters must be nil
            if let number = tag.tagged_phone_number {
                let newTagLink = TagLink(tagType: .phone, tagValue: number, tagText: tag.tagged_name)
                guard let linkString = TagLink.encodeTagLink(newTagLink) else { continue }
                links[tag.tagged_name] = linkString
            } else if let userId = tag.tagged_user {
                let newTagLink = TagLink(tagType: .id, tagValue: String(userId), tagText: tag.tagged_name)
                guard let linkString = TagLink.encodeTagLink(newTagLink) else { continue }
                links[tag.tagged_name] = linkString
            }
        }
        commentTextView.removeAllLinks()
        commentTextView.addLinks(links)
    }
    
    //MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        setupBubbleArrow()
    }
    
    //MARK: -User Interaction
        
    @IBAction func didPressedAuthorButton(_ sender: UIButton) {
        commentDelegate.handleCommentProfilePicTap(commentAuthor: author)
    }
    
    @IBAction func didPressedMoreButton(_ sender: UIButton) {
        handleMore()
    }
    
    @objc func didLongPressComment() {
        handleMore()
    }
    
    func handleMore() {
        moreButton.isEnabled = false
        commentDelegate.handleCommentMore(commentId: comment.id, commentAuthor: comment.author)
        DispatchQueue.main.async {
            self.moreButton.isEnabled = true
        }
    }
    
    @IBAction func didPressedVoteButton(_ sender: UIButton) {
        voteButton.isEnabled = false
        voteLabelButton.isEnabled = false
        voteLabelButton.isSelected = !voteLabelButton.isSelected
        voteButton.isSelected = !voteButton.isSelected
        commentDelegate.handleCommentVote(commentId: comment.id, isAdding: voteButton.isSelected)
        DispatchQueue.main.async {
            self.voteLabelButton.isEnabled = true
            self.voteButton.isEnabled = true
        }
    }
    
    //MARK: -Setup
    
//    func setupBubbleArrow() {
//        let triangleView = UIView()
//        triangleView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints
//        backgroundBubbleView.addSubview(triangleView)
//        backgroundBubbleView.sendSubviewToBack(triangleView)
//        backgroundBubbleView.becomeCommentView()
//    }
    
//    //https://stackoverflow.com/questions/30650343/triangle-uiview-swift
//    func addLeftTriangleLayer(to triangleView: UIView) {
//        //set constraints for triangle view
//        let constraints = [
//            triangleView.heightAnchor.constraint(equalToConstant: 30),
//            triangleView.widthAnchor.constraint(equalToConstant:15),
//            triangleView.bottomAnchor.constraint(equalTo: backgroundBubbleView.bottomAnchor, constant: 0),
//            triangleView.leftAnchor.constraint(equalTo: backgroundBubbleView.leftAnchor, constant: -5),
//        ]
//        NSLayoutConstraint.activate(constraints)
//        contentView.layoutIfNeeded()
//
//        let heightWidth = triangleView.frame.size.height
//        let path = CGMutablePath()
//        path.move(to: CGPoint(x: 0, y: heightWidth))
//        path.addLine(to: CGPoint(x:heightWidth/2, y: 0))
//        path.addLine(to: CGPoint(x:heightWidth/2, y:heightWidth))
//        path.addLine(to: CGPoint(x:0, y:heightWidth))
//
//        let shape = CAShapeLayer()
//        shape.path = path
//        shape.fillColor = Constants.Color.mistPink.cgColor
//        triangleView.layer.insertSublayer(shape, at: 0)
//     }
    
}
