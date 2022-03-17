//
//  OkViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

class MapModalViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var containingView: UIView!
    @IBOutlet weak var goToPostButton: UIButton!
    
    var annotation: BridgeAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cell = Bundle.main.loadNibNamed(Constants.SBID.Cell.Post, owner: self, options: nil)?[0] as! PostCell
        if let mapModalPost = annotation.post {
            cell.locationLabel.text = mapModalPost.location_description
            cell.titleLabel.text = mapModalPost.title
            cell.messageLabel.text = mapModalPost.text
            cell.commentButton.titleLabel!.text = String(mapModalPost.commentcount)
            cell.timestampLabel.text = getFormattedTimeString(postTimestamp: mapModalPost.timestamp)
        }
        let postView = cell.contentView
//        postView.frame.origin = CGPoint(x: 0, y: 0)
//        postView.sizeToFit()
        containingView.addSubview(postView)
        postView.translatesAutoresizingMaskIntoConstraints = false //allows programmatic settings of constraints

        let constraints = [
//            postView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            postView.topAnchor.constraint(equalTo: containingView.topAnchor, constant: 10),
            postView.rightAnchor.constraint(equalTo: containingView.rightAnchor, constant: -10),
            postView.leftAnchor.constraint(equalTo: containingView.leftAnchor, constant: 10),
            goToPostButton.topAnchor.constraint(equalTo: postView.bottomAnchor, constant: -60)
        ]
        NSLayoutConstraint.activate(constraints)

        containingView.sendSubviewToBack(postView)
        containingView.bringSubviewToFront(goToPostButton)
        goToPostButton.layer.cornerRadius = 5
        containingView.layer.cornerRadius = 15
    }
    
    //create a postVC for a given post. postVC should never exist without a post
    class func createMapModalVCFor(_ annotation: BridgeAnnotation) -> MapModalViewController {
        let mapModalVC =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.MapModal) as! MapModalViewController
        mapModalVC.annotation = annotation
        return mapModalVC
    }
    
    @IBAction func goToPostButtonDidPressed(_ sender: UIButton) {
        let postVC = self.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
//        postVC.post = post
//        feedVC.navigationController!.pushViewController(postVC, animated: true)
        
//        if let feedVC = parentVC as? FeedTableViewController {
//            let postVC = feedVC.storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.Post) as! PostViewController
//            postVC.post = post
//            feedVC.navigationController!.pushViewController(postVC, animated: true)
//        } else {
//            //parentViewController is a PostViewController, so don't do anything
//        }
    }
    
    //MARK: -Helpers
    
}
