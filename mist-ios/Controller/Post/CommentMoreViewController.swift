//
//  CommentMoreViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/22/22.
//

import Foundation
import UIKit

class CommentMoreViewController: CustomSheetViewController {
        
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var flagButton: ToggleButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteButtonGrayLine: UIView!

    var commentDelegate: CommentDelegate!
    var commentId: Int!
    var commentAuthor: Int!
    
    class func create(commentId: Int, commentAuthor: Int, commentDelegate: CommentDelegate) -> CommentMoreViewController {
        let commentMoreVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.CommentMore) as! CommentMoreViewController
        commentMoreVC.commentId = commentId
        commentMoreVC.commentAuthor = commentAuthor
        commentMoreVC.commentDelegate = commentDelegate
        commentMoreVC.loadViewIfNeeded() //doesnt work without this function call
        return commentMoreVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let sheetHeight: CGFloat = 160
        if commentAuthor != UserService.singleton.getId() {
            deleteButton.isHidden = true
            setupFlagButton()
        } else {
            flagButton.isHidden = true
        }
        setupSheet(prefersGrabberVisible: false,
                   detents: [._detent(withIdentifier: "s", constant: sheetHeight)],
                   largestUndimmedDetentIdentifier: nil)
        
        closeButton.layer.cornerRadius = 5
    }
    
    func setupFlagButton() {
        flagButton.selectedImage = UIImage.init(systemName: "flag.fill")!
        flagButton.notSelectedImage = UIImage.init(systemName: "flag")!
        flagButton.selectedTitle = "flagged"
        flagButton.notSelectedTitle = "flag"
        flagButton.isSelected = FlagService.singleton.hasFlaggedComment(commentId)
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func reportButton(_ sender: UIButton) {
        // UI Updates
        flagButton.isEnabled = false
        flagButton.isSelected = !flagButton.isSelected
        
        // Remote and storage updates
        commentDelegate.handleCommentFlag(commentId: commentId, isAdding: flagButton.isSelected)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func deleteButtonDidPressed(_ sender: UIButton) {
        deleteButton.isEnabled = false
        Task {
            do {
                try await CommentService.singleton.deleteComment(commentId: commentId)
                DispatchQueue.main.async { [self] in
                    dismiss(animated: true)
                    commentDelegate.handleSuccessfulCommentDelete(commentId: commentId)
                }
            } catch {
                CustomSwiftMessages.displayError(error)
                DispatchQueue.main.async { [self] in
                    dismiss(animated: true)
                }
            }
        }
    }
}
