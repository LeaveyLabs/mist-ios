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
    @IBOutlet weak var indicatorView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureWith(conversation: Conversation) {
        let isHidden = conversation.isSangdaebangHidden
        
        //TODO: if profilePic is not loaded in, we should load it in and display it
        
        profilePicImageView.becomeProfilePicImageView(with: isHidden ? conversation.sangdaebang.silhouette : conversation.sangdaebang.profilePic)
        nameLabel.text = isHidden ? "???" : conversation.sangdaebang.first_name
        messageLabel.text = conversation.messageThread.server_messages.last?.body ?? ""
        selectionStyle = .none
        verifiedImageView.isHidden = !conversation.sangdaebang.is_verified
        setupTimeLabel(conversation)
        
        if ConversationService.singleton.getUnreadConversations().contains(where: { convo in
            convo.sangdaebang.id == conversation.sangdaebang.id
        }) {
            nameLabel.font = UIFont(name: Constants.Font.Heavy, size: 25)
            messageLabel.font = UIFont(name: Constants.Font.Heavy, size: 15)
            indicatorView.isHidden = false
            indicatorView.roundCornersViaCornerRadius(radius: 7.5)
        } else {
            nameLabel.font = UIFont(name: Constants.Font.Roman, size: 25)
            messageLabel.font = UIFont(name: Constants.Font.Roman, size: 15)
            indicatorView.isHidden = true
        }
    }
    
    func setupTimeLabel(_ conversation: Conversation) {
        guard let lastMessageTime = conversation.messageThread.server_messages.last?.timestamp else { return }
        let timeSinceString = getFormattedTimeStringForConvo(timestamp: lastMessageTime)
        timeLabel.text = timeSinceString.lowercased()
    }
    
}
