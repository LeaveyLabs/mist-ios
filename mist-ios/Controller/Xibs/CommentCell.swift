//
//  CommentCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var authorProfilePicButton: UIButton!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var backgroundBubbleView: UIView!
    
    var parentVC: UIViewController!
    var comment: Comment!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupBubbleArrow()
    }
    
    func configureCommentCell(comment: Comment, parent: PostViewController) {
//        timestampLabel.text = getFormattedTimeString(postTimestamp: comment.timestamp)
        parentVC = parent
        authorLabel.text = comment.author
        commentLabel.text = comment.text
//        authorProfileImageView.image = UIImage(named: "adam")
        authorProfilePicButton.imageView?.layer.cornerRadius = authorProfilePicButton.frame.size.height / 2
        authorProfilePicButton.imageView?.layer.cornerCurve = .continuous
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    //MARK: -User Interaction
        
    @IBAction func didPressedAuthorProfilePic(_ sender: UIButton) {
        //presnet profile modal
    }
    
    
    //MARK: -Setup
    
    func setupBubbleArrow() {
        let triangleView = UIView()
        triangleView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints
        backgroundBubbleView.addSubview(triangleView)
        backgroundBubbleView.sendSubviewToBack(triangleView)
        addLeftTriangleLayer(to: triangleView)
        backgroundBubbleView.layer.cornerRadius = 10
        backgroundBubbleView.layer.cornerCurve = .continuous //TODO: this is not looking continuous
//        applyShadowOnView(backgroundBubbleView)
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
