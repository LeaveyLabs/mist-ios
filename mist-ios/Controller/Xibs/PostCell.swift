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
    
    var parentVC: UIViewController!
    var post: Post!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configurePostCell(post: Post, parent: UIViewController) {
        parentVC = parent
        self.post = post
        timestampLabel.text = getFormattedTimeString(postTimestamp: post.timestamp)
        locationLabel.text = post.location
        messageLabel.text = post.text
        titleLabel.text = post.title
        commentButton.setTitle(" " + String(post.commentcount), for: .normal)
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