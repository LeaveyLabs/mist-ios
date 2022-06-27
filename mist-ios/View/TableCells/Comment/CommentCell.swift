//
//  CommentCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

protocol CommentDelegate {
    func handleCommentProfilePicTap(commentAuthor: FrontendReadOnlyUser)
}

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
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var backgroundBubbleView: UIView!
    @IBOutlet weak var timestampLabel: UILabel!
    
    //Information
    var comment: Comment!
    var author: FrontendReadOnlyUser!
    
    //Delegate
    var commentDelegate: CommentDelegate!

    
    //MARK: - Initializer
    
    func configureCommentCell(comment: Comment, delegate: CommentDelegate, author: FrontendReadOnlyUser) {
        self.comment = comment
        self.commentDelegate = delegate
        self.author = author
        timestampLabel.text = getShortFormattedTimeString(timestamp: comment.timestamp)
        authorUsernameButton.setTitle("@" + author.username, for: .normal)
        commentLabel.text = comment.body
        UIView.performWithoutAnimation {
            authorProfilePicButton.imageView?.becomeProfilePicImageView(with: author.profilePic)
        }
    }
    
    //MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupBubbleArrow()
    }
    
    //MARK: -User Interaction
        
    @IBAction func didPressedAuthorButton(_ sender: UIButton) {
        commentDelegate.handleCommentProfilePicTap(commentAuthor: author)
    }
    
    //MARK: -Setup
    
    func setupBubbleArrow() {
        let triangleView = UIView()
        triangleView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints
        backgroundBubbleView.addSubview(triangleView)
        backgroundBubbleView.sendSubviewToBack(triangleView)
        backgroundBubbleView.becomeCommentView()
    }
    
    //https://stackoverflow.com/questions/30650343/triangle-uiview-swift
    func addLeftTriangleLayer(to triangleView: UIView) {
        //set constraints for triangle view
        let constraints = [
            triangleView.heightAnchor.constraint(equalToConstant: 30),
            triangleView.widthAnchor.constraint(equalToConstant:15),
            triangleView.bottomAnchor.constraint(equalTo: backgroundBubbleView.bottomAnchor, constant: 0),
            triangleView.leftAnchor.constraint(equalTo: backgroundBubbleView.leftAnchor, constant: -5),
        ]
        NSLayoutConstraint.activate(constraints)
        contentView.layoutIfNeeded()
        
        let heightWidth = triangleView.frame.size.height
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: heightWidth))
        path.addLine(to: CGPoint(x:heightWidth/2, y: 0))
        path.addLine(to: CGPoint(x:heightWidth/2, y:heightWidth))
        path.addLine(to: CGPoint(x:0, y:heightWidth))
        
        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = mistSecondaryUIColor().cgColor
        triangleView.layer.insertSublayer(shape, at: 0)
     }
    
}