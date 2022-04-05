//
//  PostTableViewCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit
import Social

class PostCell: UITableViewCell {

    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    
    @IBOutlet var moreButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet var shareButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    
    @IBOutlet weak var backgroundBubbleView: UIView!
    
    var parentVC: UIViewController!
    var post: Post!
    var triangleSublayer: CALayer?
    var firstLoad: Bool = true
    
//    let cellView: UIView = {
//            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//            view.layer.cornerRadius  = 15
//            view.backgroundColor     = UIColor.white
//            view.layer.shadowColor   = UIColor.black.cgColor
//            view.layer.shadowOpacity = 1
//            view.layer.shadowOffset  = CGSize.zero
//            view.layer.shadowRadius  = 5
//            return view
//        }()
//
//        override func awakeFromNib() {
//            super.awakeFromNib()
//            addSubview(cellView)
//        }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
//        backgroundImage.image = UIImage(named: "textbox")
//        backgroundImage.contentMode = .scaleToFill
//        backgroundImage.clipsToBounds = false
//        contentView.insertSubview(backgroundImage, at: 0)
//
//        backgroundColor = mistUIColor()
        backgroundBubbleView.layer.cornerRadius = 20
        backgroundBubbleView.layer.cornerCurve = .continuous
        applyShadowOnView(backgroundBubbleView)

//        backgroundBubbleView.clipsToBounds = true we dont want this because then the triangle cant extend beyond
        
        for constraint in contentView.constraints {
            if constraint.identifier == "leftBubbleConstraint" {
               constraint.constant = 25
            }
        }
        contentView.layoutIfNeeded()
        print("awake from nib")
    }
    
    override func prepareForReuse() {
        print("prepare for reuse")
        triangleSublayer?.removeFromSuperlayer()
    }
    
    override func layoutSubviews() {
        print("layout Subviews")
        triangleSublayer = getLeftTriangleSublayer()
        backgroundBubbleView.layer.insertSublayer(triangleSublayer!, at: 0)

//        if (firstLoad) {
//            firstLoad = false
//            backgroundBubbleView.layer.insertSublayer(triangleSublayer!, at: 0)
//        } else {
//            let oldTriangleSublayer = triangleSublayer!
//            triangleSublayer = getLeftTriangleSublayer()
//            contentView.layer.replaceSublayer(oldTriangleSublayer, with: triangleSublayer!)
//        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configurePostCell(post: Post, parent: UIViewController) {
        parentVC = parent
        self.post = post
        timestampLabel.text = getFormattedTimeString(postTimestamp: post.timestamp)
        locationLabel.text = post.location_description
        messageLabel.text = post.text
        titleLabel.text = post.title
        commentButton.setTitle(" " + String(post.commentcount), for: .normal)
    }
    
    //https://stackoverflow.com/questions/30650343/triangle-uiview-swift
    func getLeftTriangleSublayer() -> CALayer {
        let heightWidth = backgroundBubbleView.frame.size.width / 6
        let bottom = backgroundBubbleView.frame.size.height
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -10, y: bottom))
        path.addLine(to: CGPoint(x:0, y: bottom - heightWidth))
        path.addLine(to: CGPoint(x:20, y:bottom))
        path.addLine(to: CGPoint(x:-10, y:bottom))
        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = mistSecondaryUIColor().cgColor
        
        return shape
     }
    
    @IBAction func commentButtonDidPressed(_ sender: UIButton) {
        if let feedVC = parentVC as? FeedTableViewController {
            let postVC = feedVC.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
            postVC.post = post
            postVC.completionHandler = {
                Post in feedVC.tableView.reloadData()
            }
            feedVC.navigationController!.pushViewController(postVC, animated: true)
        } else {
            //parentViewController is a PostViewController, so don't do anything
        }
    }
    
    @IBAction func moreButtonDidPressed(_ sender: UIButton) {
        let moreVC = parentVC.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.More) as! MoreViewController

        if let sheet = moreVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        parentVC.present(moreVC, animated: true, completion: nil)
    }
    
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
}
