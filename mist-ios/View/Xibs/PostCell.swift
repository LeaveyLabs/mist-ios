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
    var post: Post?
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func commentButtonDidPressed(_ sender: UIButton) {
        if let parentViewController = parentViewController as? FeedTableViewController {
            parentViewController.selectedPostIndex = parentViewController.tableView.indexPath(for: self)!.row
            print(parentViewController.selectedPostIndex!)
            parentViewController.performSegue(withIdentifier: "FeedToPost", sender: parentViewController)
        } else {
            
        }
    }
    
    @IBAction func shareButtonClicked(sender: UIButton) {
        //TODO: use Open Graph protocols on our website for a Rich imessage display
        //https://developer.apple.com/library/archive/technotes/tn2444/_index.html
        if let url = NSURL(string: "https://www.getmist.app")  {
            let objectsToShare: [Any] = [url]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = parentViewController?.view // so that iPads won't crash
            parentViewController!.present(activityVC, animated: true, completion: nil)
        }
    }
}
