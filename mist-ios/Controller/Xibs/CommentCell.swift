//
//  CommentCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var authorProfileImageView: UIImageView!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    var parentVC: UIViewController!
    var comment: Comment!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCommentCell(comment: Comment, parent: PostViewController) {
        timestampLabel.text = getFormattedTimeString(postTimestamp: comment.timestamp)
        parentVC = parent
        authorLabel.text = comment.author
        commentLabel.text = comment.text
        authorProfileImageView.image = UIImage(named: "pic4")
        authorProfileImageView.layer.cornerRadius = authorProfileImageView.frame.size.height / 2
        authorProfileImageView.layer.cornerCurve = .continuous
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
