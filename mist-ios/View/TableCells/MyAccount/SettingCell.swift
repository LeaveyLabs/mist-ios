//
//  MyAccountCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/11.
//

import UIKit

class SettingCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var accessoryLabel: UILabel!
    @IBOutlet weak var accessoryImageView: UIImageView!
        
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func configure(setting: Setting) {
        iconImageView.image = setting.iconImage
        titleLabel.text = setting.displayName
        accessoryLabel.text = ""
        accessoryImageView.isHidden = false
        selectionStyle = .default
        
        switch setting {
        case .friends:
            //TODO: notifications for new friends
            break
        case .mentions:
            accessoryLabel.text = String(PostService.singleton.getMentions().count)
        case .submissions:
            accessoryLabel.text = String(PostService.singleton.getSubmissions().count)
        case .favorites:
            accessoryLabel.text = String(PostService.singleton.getFavorites().count)
        case .settings:
            break
        case .shareFeedback:
            break
        case .learnMore:
            break
        case .email:
            accessoryLabel.text = UserService.singleton.getEmail()
            accessoryImageView.isHidden = true
            selectionStyle = .none
        case .phoneNumber:
            accessoryLabel.text = UserService.singleton.getPhoneNumber()
        case .deleteAccount:
            break
        case .contactUs:
            accessoryLabel.text = "whatsup@getmist.app"
        case .leaveReview:
            break
        case .faq:
            break
        case .contentGuidelines:
            break
        case .privacyPolicy:
            break
        case .terms:
            break
        case .rateMist:
            break
        }
    }
}
