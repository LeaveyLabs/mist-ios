//
//  DmViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/12.
//

import UIKit

class NewMessageViewController: UIViewController {
    
    //MARK: - Propreties

    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBOutlet weak var authorProfilePic: UIImageView!
    
    var postId: Int!
    var authorId: Int!
    
    //MARK: - Initialization
    
    class func create(postId: Int, authorId: Int) -> NewMessageViewController {
        let newMessageVC =
        UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.NewMessage) as! NewMessageViewController
        newMessageVC.postId = postId
        newMessageVC.authorId = authorId
        return newMessageVC
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authorProfilePic.image = authorProfilePic.image!.blur()
    }
    
    //MARK: - User Interaction

    @IBAction func xButtonDidPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
    
    @IBAction func sendButtonDidPressed(_ sender: UIBarButtonItem) {
        
    }
}
