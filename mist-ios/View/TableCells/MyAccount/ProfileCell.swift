//
//  MyProfileTableViewCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/10.
//

import UIKit

class ProfileCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var verifiedImageView: UIImageView!
    @IBOutlet weak var accessoryImageView: UIImageView!
    
    var setting: Setting!
        
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        if setting == .myProfile {
            configureMyProfileCell()
        } else if setting == .avatar {
            configureAvatarCell()
        }
    }
    
    func configure(setting: Setting) {
        if setting == .myProfile {
            configureMyProfileCell()
        } else if setting == .avatar {
            configureAvatarCell()
        }
    }
    
    func configureMyProfileCell() {
        selectionStyle = .default
        accessoryImageView.isHidden = false
        nameLabel.text = UserService.singleton.getFirstLastName()
        usernameLabel.text = UserService.singleton.getUsername()
        profileImageView.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
        verifiedImageView.isHidden = false
        verifiedImageView.image = UserService.singleton.isVerified() ? UIImage(systemName: "checkmark.seal.fill") : nil
    }
    
    func configureAvatarCell() {
        selectionStyle = .none
        accessoryImageView.isHidden = true
        nameLabel.text = "avatar"
        usernameLabel.text = "coming soon"
        profileImageView.becomeProfilePicImageView(with: UserService.singleton.getSilhouette())
        verifiedImageView.isHidden = true
        verifiedImageView.image = UserService.singleton.isVerified() ? UIImage(systemName: "checkmark.seal.fill") : nil
    }
}
