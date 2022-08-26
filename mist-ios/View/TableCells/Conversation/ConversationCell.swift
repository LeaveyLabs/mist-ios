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
    @IBOutlet weak var verifiedImageView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureWith(conversation: Conversation) {
        let isHidden = conversation.isSangdaebangHidden
        profilePicImageView.becomeProfilePicImageView(with: isHidden ? conversation.sangdaebang.blurredPic : conversation.sangdaebang.profilePic)
        nameLabel.text = isHidden ? "???" : conversation.sangdaebang.first_name
        messageLabel.text = conversation.messageThread.server_messages.last?.body ?? ""
        selectionStyle = .none
        verifiedImageView.isHidden = !conversation.sangdaebang.is_verified
        setupTimeLabel(conversation)
    }
    
    func setupTimeLabel(_ conversation: Conversation) {
        guard let lastMessageTime = conversation.messageThread.server_messages.first?.timestamp else { return }
        let timeSinceString = getFormattedTimeString(timestamp: lastMessageTime)
        timeLabel.text = timeSinceString
    }
    
}
