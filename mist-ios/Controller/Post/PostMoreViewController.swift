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
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteButtonGrayLine: UIView!

    var postDelegate: PostDelegate!
    var postId: Int!
    var postAuthor: Int!
    
    class func create(postId: Int, postAuthor: Int, postDelegate: PostDelegate) -> PostMoreViewController {
        let postMoreVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.PostMore) as! PostMoreViewController
        postMoreVC.postId = postId
        postMoreVC.postAuthor = postAuthor
        postMoreVC.postDelegate = postDelegate
        postMoreVC.loadViewIfNeeded() //doesnt work without this function call
        return postMoreVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var sheetHeight: CGFloat = 370
        print(postAuthor != UserService.singleton.getId())
        if postAuthor != UserService.singleton.getId() {
            deleteButton.isHidden = true
            deleteButtonGrayLine.isHidden = true
            sheetHeight -= 70
        }
        setupSheet(prefersGrabberVisible: false,
                   detents: [._detent(withIdentifier: "s", constant: sheetHeight)],
                   largestUndimmedDetentIdentifier: nil)
        
        closeButton.layer.cornerRadius = 5
        
        flagButton.selectedImage = UIImage.init(systemName: "flag.fill")!
        flagButton.notSelectedImage = UIImage.init(systemName: "flag")!
        flagButton.selectedTitle = "flagged"
        flagButton.notSelectedTitle = "flag"
        favoriteButton.selectedImage = UIImage(systemName: "bookmark.fill")!
        favoriteButton.notSelectedImage = UIImage(systemName: "bookmark")!
        favoriteButton.selectedTitle = "favorited"
        favoriteButton.notSelectedTitle = "favorite"
        
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.favoriteButton.isEnabled = true
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func reportButton(_ sender: UIButton) {
        // UI Updates
        flagButton.isEnabled = false
        flagButton.isSelected = !flagButton.isSelected
        
        // Remote and storage updates
        postDelegate?.handleFlag(postId: postId, isAdding: flagButton.isSelected)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.flagButton.isEnabled = true
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func deleteButtonDidPressed(_ sender: UIButton) {
        CustomSwiftMessages.showAlert(title: "delete this mist", body: "are you sure you want to delete this mist? this can't be undone.", emoji: "😟", dismissText: "nevermind", approveText: "delete", onDismiss: {
            
        }, onApprove: { [self] in
            deleteButton.isEnabled = false
            Task {
                do {
                    try await PostService.singleton.deletePost(postId: postId)
                    DispatchQueue.main.async { [self] in
                        dismiss(animated: true)
                        deleteButton.isEnabled = true
                        postDelegate.handleDeletePost(postId: postId)
                    }
                } catch {
                    CustomSwiftMessages.displayError(error)
                    DispatchQueue.main.async { [self] in
                        dismiss(animated: true)
                    }
                }
            }
        })
    }
}
