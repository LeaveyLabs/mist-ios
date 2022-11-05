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
    @IBOutlet weak var accessoryLabel: UILabel! //for non notifications
    @IBOutlet weak var accessoryIndicatorBackgroundView: UIView! //for notifications
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
        accessoryLabel.textColor = Constants.Color.mistBlack
        selectionStyle = .default
        accessoryIndicatorBackgroundView.isHidden = true
        accessoryLabel.font = UIFont(name: Constants.Font.Medium, size: 13)
        accessoryImageView.isHidden = false
        
        switch setting {
//        case .mentions:
//            if DeviceService.shared.unreadMentionsCount() > 0 {
//                accessoryIndicatorBackgroundView.roundCornersViaCornerRadius(radius: 12.5)
//                accessoryIndicatorBackgroundView.isHidden = false
//                accessoryLabel.textColor = .white
//                print("unread mentions", DeviceService.shared.unreadMentionsCount())
//                accessoryLabel.text = String(DeviceService.shared.unreadMentionsCount())
//            } else {
//                accessoryLabel.text = String(PostService.singleton.getMentions().count)
//            }
//            accessoryLabel.font = UIFont(name: Constants.Font.Medium, size: 15)
//        case .submissions:
//            accessoryLabel.text = String(PostService.singleton.getSubmissions().count)
//            accessoryLabel.font = UIFont(name: Constants.Font.Medium, size: 15)
//        case .favorites:
//            accessoryLabel.text = String(PostService.singleton.getFavorites().count)
//            accessoryLabel.font = UIFont(name: Constants.Font.Medium, size: 15)
        case .account:
            break
        case .logout:
            break
        case .notifications:
            selectionStyle = .none
            accessoryImageView.isHidden = true
            accessoryLabel.text = "coming soon"
        case .shareFeedback:
            break
        case .mistableMoments, .whenAmIAnonymous, .howDoesMistWork, .inHouseFaq:
            break
        case .learnMore:
            break
        case .phoneNumber:
            accessoryImageView.isHidden = true
            selectionStyle = .none
            accessoryLabel.text = UserService.singleton.getPhoneNumberPretty()
        case .deleteAccount:
            break
        case .contactUs:
            accessoryLabel.text = "whatsup@getmist.app"
        case .leaveReview:
            break
        case .feedbackForm:
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
        case .merch:
            accessoryLabel.text = Constants.merchLinkName
        case .instagram:
            accessoryLabel.text = Constants.instagramHandle
        }
    }
}
