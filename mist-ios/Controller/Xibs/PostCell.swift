//
//  PostTableViewCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit
import Social

enum BubbleArrowPosition {
    case left
    case bottom
    case right
}

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
    
    var parentVC: UIViewController!
    var post: Post!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("awake from nib")
    }
    
    override func prepareForReuse() {
        print("prepare for reuse")
    }
    
    override func layoutSubviews() {
        print("layout Subviews")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    //MARK: -Constructor
    
    func configurePostCell(post: Post, parent: UIViewController, bubbleArrowPosition: BubbleArrowPosition) {
        parentVC = parent
        self.post = post
        timestampLabel.text = getFormattedTimeString(postTimestamp: post.timestamp)
        locationLabel.text = post.location_description
        messageLabel.text = post.text
        titleLabel.text = post.title
        likeLabel.text = String(post.averagerating)
        
        setupBubbleArrow(at: bubbleArrowPosition)
        
        likeButton.isSelected = false
        favoriteButton.isSelected = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        backgroundBubbleView.addGestureRecognizer(tapGesture)
    }
    
    //MARK: -User Interaction
    
    @objc func tapAction() {
        sendToPost(withRaisedKeyboard: false)
    }
    
    @IBAction func likeButtonDidPressed(_ sender: UIButton) {
        //if not liked, then like
        if (!likeButton.isSelected) {
            likeLabel.text = String(Int(likeLabel.text!)! + 1)
        }
        //if liked, then unlike
        else {
            likeLabel.text = String(Int(likeLabel.text!)! - 1)
        }
        likeButton.isSelected = !likeButton.isSelected
    }
    
    @IBAction func commentButtonDidPressed(_ sender: UIButton) {
        sendToPost(withRaisedKeyboard: true)
    }
    
    @IBAction func dmButtonDidPressed(_ sender: UIButton) {
        
    }
    
    @IBAction func favoriteButtonDidpressed(_ sender: UIButton) {
        //if not liked, then like
        if (!favoriteButton.isSelected) {
            
        }
        //if liked, then unlike
        else {

        }
        favoriteButton.isSelected = !favoriteButton.isSelected
    }
    
    @IBAction func moreButtonDidPressed(_ sender: UIButton) {
        let moreVC = parentVC.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.More) as! MoreViewController

        if let sheet = moreVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        parentVC.present(moreVC, animated: true, completion: nil)
    }
    
    //MARK: -Setup
    
    func setupBubbleArrow(at bubbleArrowPosition: BubbleArrowPosition) {
        let triangleView = UIView()
        triangleView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints
        backgroundBubbleView.addSubview(triangleView)
        backgroundBubbleView.sendSubviewToBack(triangleView)
        switch bubbleArrowPosition {
        case .left:
            addLeftTriangleLayer(to: triangleView)
        case .bottom:
            addBottomTriangleLayer(to: triangleView)
        case .right:
            addRightTriangleLayer(to: triangleView)
        }
        backgroundBubbleView.layer.cornerRadius = 20 //TODO: how do i add a corner radius to the triangle, too?
        backgroundBubbleView.layer.cornerCurve = .continuous
        applyShadowOnView(backgroundBubbleView)
    }
    
    //https://stackoverflow.com/questions/30650343/triangle-uiview-swift
    func addLeftTriangleLayer(to triangleView: UIView) {
        //set constraints for triangle view
        let constraints = [
            triangleView.heightAnchor.constraint(equalToConstant: 80),
            triangleView.widthAnchor.constraint(equalToConstant: 80),
            triangleView.bottomAnchor.constraint(equalTo: backgroundBubbleView.bottomAnchor, constant: 0),
            triangleView.leftAnchor.constraint(equalTo: backgroundBubbleView.leftAnchor, constant: -10),
        ]
        //fix the width constraint of the bubble
        for constraint in contentView.constraints {
            if constraint.identifier == "leftBubbleConstraint" {
               constraint.constant = 20
            }
        }
        NSLayoutConstraint.activate(constraints)
        contentView.layoutIfNeeded()
        
        let heightWidth = triangleView.frame.size.height
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: heightWidth))
        path.addLine(to: CGPoint(x:heightWidth/2, y: -30))
        path.addLine(to: CGPoint(x:heightWidth/2, y:heightWidth))
        path.addLine(to: CGPoint(x:0, y:heightWidth))
        
        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = mistSecondaryUIColor().cgColor
        triangleView.layer.insertSublayer(shape, at: 0)
     }
    
    func addRightTriangleLayer(to triangleView: UIView) {
        //set constraints for triangle view
        let constraints = [
            triangleView.heightAnchor.constraint(equalToConstant: 80),
            triangleView.widthAnchor.constraint(equalToConstant: 80),
            triangleView.bottomAnchor.constraint(equalTo: backgroundBubbleView.bottomAnchor, constant: 0),
            triangleView.rightAnchor.constraint(equalTo: backgroundBubbleView.rightAnchor, constant: 10),
        ]
        //fix the width constraint of the bubble
        for constraint in contentView.constraints {
            if constraint.identifier == "rightBubbleConstraint" {
               constraint.constant = 20
            }
        }
        NSLayoutConstraint.activate(constraints)
        contentView.layoutIfNeeded()
        
        let heightWidth = triangleView.frame.size.height
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: heightWidth))
        path.addLine(to: CGPoint(x:heightWidth/2, y: -30))
        path.addLine(to: CGPoint(x:heightWidth, y:heightWidth))
        path.addLine(to: CGPoint(x:0, y:heightWidth))
        
        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = mistSecondaryUIColor().cgColor
        triangleView.layer.insertSublayer(shape, at: 0)
     }
    
    func addBottomTriangleLayer(to triangleView: UIView) {
        //set constraints for triangle view
        let constraints = [
            triangleView.heightAnchor.constraint(equalToConstant: 80),
            triangleView.widthAnchor.constraint(equalToConstant: 80),
            triangleView.bottomAnchor.constraint(equalTo: backgroundBubbleView.bottomAnchor, constant: 0),
            triangleView.centerXAnchor.constraint(equalTo: backgroundBubbleView.centerXAnchor, constant: 0),
        ]
        //fix the HEIGHT constraint of the bubble
        for constraint in contentView.constraints {
            if constraint.identifier == "bottomBubbleConstraint" {
               constraint.constant = 35
            }
        }
        NSLayoutConstraint.activate(constraints)
        contentView.layoutIfNeeded()
        
        let heightWidth = triangleView.frame.size.height
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: heightWidth))
        path.addLine(to: CGPoint(x:heightWidth/2, y: heightWidth + 30))
        path.addLine(to: CGPoint(x:heightWidth, y:heightWidth))
        path.addLine(to: CGPoint(x:0, y:heightWidth))
        
        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = mistSecondaryUIColor().cgColor
        triangleView.layer.insertSublayer(shape, at: 0)
     }
    
    //MARK: -Decomissioned
    
    @IBAction func shareButtonClicked(sender: UIButton) {
        //TODO: use Open Graph protocols on our website for a Rich imessage display
        //https://developer.apple.com/library/archive/technotes/tn2444/_index.html
        if let url = NSURL(string: "https://www.getmist.app")  {
            let objectsToShare: [Any] = [url]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = parentVC.view // so that iPads won't crash
            parentVC.present(activityVC, animated: true, completion: nil)
        }
    }
    
    //MARK: -Helpers
    
    func sendToPost(withRaisedKeyboard: Bool) {
        if let feedVC = parentVC as? FeedViewController {
            let postVC = feedVC.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
            postVC.post = post
            postVC.shouldStartWithRaisedKeyboard = withRaisedKeyboard
            postVC.completionHandler = {
                Post in feedVC.tableView.reloadData()
            }
            feedVC.navigationController!.pushViewController(postVC, animated: true)
        }
    }
}
