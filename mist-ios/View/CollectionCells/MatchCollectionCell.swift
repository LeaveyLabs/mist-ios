//
//  MatchCollectionCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/30/22.
//

import UIKit
import MessageKit

protocol MatchRequestCellDelegate {
    func matchRequestCellDidTapped(postId: Int)
}

class MatchCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var moreIndicator: UIImageView!
    @IBOutlet weak var timestampLabel: UILabel!
    
    var matchRequestCellDelegate: MatchRequestCellDelegate!
    var postId: Int!

    override func awakeFromNib() {
        super.awakeFromNib()
        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(backgroundButtonDidPressed))
        bgView.addGestureRecognizer(backgroundTap)
    }
    
    open func configure(with messageKitMatch: MessageKitMatchRequest,
                        sangdaebang: FrontendReadOnlyUser,
                        delegate: MatchRequestCellDelegate,
                        isSangdaebangHidden: Bool) {
        matchRequestCellDelegate = delegate
        postId = messageKitMatch.matchRequest.post
        
        let theirName = isSangdaebangHidden ? "???" : sangdaebang.first_name
        subtitleLabel.text = messageKitMatch.matchRequest.match_requesting_user == UserService.singleton.getId() ?
            "You replied to " + theirName + "'s mist:" :
            theirName + " replied to your mist:"
        titleLabel.text = messageKitMatch.postTitle

        //the matchRequest.post is nil if the post was deleted upon load in
        //PostService.singleton.getPost is nil if the post was deleted during user's session
        if let postId = messageKitMatch.matchRequest.post, let _ = PostService.singleton.getPost(withPostId: postId) {
            moreIndicator.isHidden = false
            bgView.gestureRecognizers?.forEach({ $0.isEnabled = true })
        } else {
            moreIndicator.isHidden = true
            bgView.gestureRecognizers?.forEach({ $0.isEnabled = false })
            
            let isPlaceholderMatchRequest = messageKitMatch.matchRequest.id == MatchRequest.PLACEHOLDER_ID
            if !isPlaceholderMatchRequest {
                titleLabel.text = MatchRequest.DELETED_POST_TITLE
            }
        }
        
        timestampLabel.attributedText = NSAttributedString(string: MessageKitDateFormatter.shared.string(from: messageKitMatch.sentDate), attributes: [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 11)!, NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
    
    @objc func backgroundButtonDidPressed() {
        matchRequestCellDelegate.matchRequestCellDidTapped(postId: postId)
    }

}