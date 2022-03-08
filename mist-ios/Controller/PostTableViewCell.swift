//
//  PostTableViewCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit
import Social

class PostTableViewCell: UITableViewCell {

    @IBOutlet var geostampLabel: UILabel!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var upvoteButton: UIButton!
    @IBOutlet var downvoteButton: UIButton!
    @IBOutlet var favoriteButton: UIButton!
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var shareButton: UIButton!
    var parentViewController: UIViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func shareButtonClicked(sender: UIButton) {
        let textToShare = "이거 너무 재밌지 않아? 얼론 찾아봐!"
        /*
        let vc = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
        parentViewController?.present(vc!, animated: true)

        let asdf = SLComposeViewController()

        let asdf2 = SLComposeServiceViewController()
        
        */
        
        //use a universal link. it looks like a URL but launches the app in safari
        
        //use Open Graph for a Rich imessage experience
        if let myWebsite = NSURL(string: "http://www.inssajeon.com/") {
            let postToTwitter = UIActivity.ActivityType.postToTwitter
            
            let postToFacebook = UIActivity.ActivityType.postToFacebook
            let image = UIImage(named: "inssajeonWideLogo")
            
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
