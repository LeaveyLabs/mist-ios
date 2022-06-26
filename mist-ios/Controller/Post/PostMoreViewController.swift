//
//  OkViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class PostMoreViewController: CustomSheetViewController {
        
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var favoriteButton: ToggleButton!
    @IBOutlet weak var flagButton: ToggleButton!

    var postDelegate: PostDelegate!
    var postId: Int!
    
    class func create(postId: Int, postDelegate: PostDelegate) -> PostMoreViewController {
        let postMoreVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.PostMore) as! PostMoreViewController
        postMoreVC.postId = postId
        postMoreVC.postDelegate = postDelegate
        postMoreVC.loadViewIfNeeded() //doesnt work without this function call
        return postMoreVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.layer.cornerRadius = 5
        setupSheet(prefersGrabberVisible: false,
                   detents: [._detent(withIdentifier: "s", constant: 300)],
                   largestUndimmedDetentIdentifier: nil)
        
        flagButton.isSelectedImage = UIImage.init(systemName: "flag.fill")!
        flagButton.isNotSelectedImage = UIImage.init(systemName: "flag")!
        flagButton.isSelectedTitle = "Flagged"
        flagButton.isNotSelectedTitle = "Flag"
        favoriteButton.isSelectedImage = UIImage(systemName: "bookmark.fill")!
        favoriteButton.isNotSelectedImage = UIImage(systemName: "bookmark")!
        favoriteButton.isSelectedTitle = "Saved"
        favoriteButton.isNotSelectedTitle = "Save"
        
        flagButton.isSelected = FlagService.singleton.hasFlaggedPost(postId)
        favoriteButton.isSelected = FavoriteService.singleton.hasFavoritedPost(postId)
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func shareButton(_ sender: UIButton) {
        dismiss(animated: true) { [self] in
            postDelegate.presentShareActivityVC()
        }
    }
    
    @IBAction func favoriteButtonDidpressed(_ sender: UIButton) {
        // UI Updates
        favoriteButton.isEnabled = false
        favoriteButton.isSelected = !favoriteButton.isSelected
        
        // Remote and storage updates
        postDelegate?.handleFavorite(postId: postId, isAdding: favoriteButton.isSelected)
        favoriteButton.isEnabled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func reportButton(_ sender: UIButton) {
        // UI Updates
        flagButton.isEnabled = false
        flagButton.isSelected = !flagButton.isSelected
        
        // Remote and storage updates
        postDelegate?.handleFlag(postId: postId, isAdding: flagButton.isSelected)
        flagButton.isEnabled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.dismiss(animated: true)
        }
    }
}
