//
//  PostShareViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 10/10/22.
//

import Foundation
import UIKit

class PostShareViewController: UIViewController {
        
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var instgramStoryButton: UIButton!
    @IBOutlet weak var shareOtherButton: UIButton!
    @IBOutlet weak var backgroundView: UIView!

    var postDelegate: PostDelegate!
    var postId: Int!
    var postScreenshot: UIImage!
    
    class func create(postId: Int, postScreenshot: UIImage, postDelegate: PostDelegate) -> PostShareViewController {
        let postShareVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.PostShare) as! PostShareViewController
        postShareVC.postId = postId
        postShareVC.postScreenshot = postScreenshot
        postShareVC.postDelegate = postDelegate
        return postShareVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        let longPress = UILongPressGestureRecognizer(target: self.slider, action: #selector(tapAndSlide(gesture: )))
//        longPress.minimumPressDuration = 0
//        view.addGestureRecognizer(longPress)
    }
    
    func setupBackgroundView() {
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(closeButtonDidPressed(_:)))
        view.addGestureRecognizer(dismissTap)
        backgroundView.layer.cornerRadius = 10
        backgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    
    //MARK: - User Interaction
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
//    @IBAction func textButtonDidPressed(_ sender: UIButton) {
//        dismiss(animated: true)
//        postDelegate.handleiMessageShare(postId: postId, screenshot: postScreenshot)
//    }
//    
//    @IBAction func tagButtonDidPressed(_ sender: UIButton) {
//        dismiss(animated: true)
//        postDelegate.handleCommentButtonTap(postId: postId)
//    }
//    
//    @IBAction func instagramStoryButtonDidPressed(_ sender: UIButton) {
//        postDelegate.handleInstagramShare(postId: postId, screenshot: postScreenshot)
//    }
    
    @IBAction func shareOtherButtonDidPressed(_ sender: UIButton) {
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            (self.postDelegate as! UIViewController).shareImage(imageToShare: self.postScreenshot, url: Constants.landingPageLink as URL)
        }
    }
    
}
