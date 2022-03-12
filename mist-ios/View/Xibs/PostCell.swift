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
    
    var parentViewController: UIViewController?
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func commentButtonDidPressed(_ sender: UIButton) {
        if let parentViewController = parentViewController as? FeedTableViewController {
            parentViewController.selectedPostIndex = parentViewController.tableView.indexPath(for: self)!.row
            print(parentViewController.selectedPostIndex!)
            parentViewController.performSegue(withIdentifier: "FeedToPost", sender: parentViewController)
        } else if (true) {
            
        }
    }
    
    @IBAction func shareButtonClicked(sender: UIButton) {
        //use a universal link. it looks like a URL but launches the app in safari
        //use Open Graph for a Rich imessage experience
        
        let textToShare = "mist: find your missed connection"

        //https://developer.apple.com/library/archive/technotes/tn2444/_index.html
        if let myWebsite = NSURL(string: "http://www.getmist.app") {
            let postToTwitter = UIActivity.ActivityType.postToTwitter
            let postToFacebook = UIActivity.ActivityType.postToFacebook
            let image = UIImage(named: "AppIcon")
            
            let objectsToShare: [Any] = [textToShare, image!]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = parentViewController?.view // so that iPads won't crash
        
            //New Excluded Activities Code
            //activityVC.excludedActivityTypes = []
            //
            parentViewController!.present(activityVC, animated: true, completion: nil)
        }
    }
}
