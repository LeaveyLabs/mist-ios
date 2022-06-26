//
//  ConversationCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import UIKit

class ConversationCell: UITableViewCell {
    
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureWith(conversation: Conversation) {
        let isHidden = !MatchRequestService.singleton.hasReceivedMatchRequestFrom(conversation.sangdaebang.id)
        profilePicImageView.becomeProfilePicImageView(with: isHidden ? conversation.sangdaebang.profilePic.blur() : conversation.sangdaebang.profilePic)
        nameLabel.text = isHidden ? "???" : conversation.sangdaebang.first_name
        messageLabel.text = conversation.messageThread.server_messages.last!.body
    }
    
}
