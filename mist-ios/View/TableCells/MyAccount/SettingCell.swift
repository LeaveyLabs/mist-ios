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
        
        if setting == .email {
            accessoryLabel.text = UserService.singleton.getEmail()
            accessoryImageView.isHidden = true
            selectionStyle = .none
        }
        if setting == .phoneNumber {
//            accessoryLabel.text = UserService.singleton.getPhoneNumber()
            accessoryImageView.isHidden = true
            selectionStyle = .none
        }
        if setting == .submissions {
            accessoryLabel.text = String(PostService.singleton.getSubmissions().count)
        }
        if setting == .favorites {
            accessoryLabel.text = String(PostService.singleton.getFavorites().count)
        }
        if setting == .contactUs {
            accessoryLabel.text = "whatsup@getmist.app"
        }
    }
}
