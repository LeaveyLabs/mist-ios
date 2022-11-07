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
    @IBOutlet weak var shadowBGView: UIView!
    
    var profileType: ProfileType!
    
    enum ProfileType: Int {
        case profile, avatar
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
        shadowBGView.applyMediumShadow()
        shadowBGView.roundCornersViaCornerRadius(radius: 10)
        selectionStyle = .none
    }
    
    override func prepareForReuse() {
        if profileType == .profile {
            configureMyProfileCell()
        } else if profileType == .avatar {
            configureAvatarCell()
        }
    }
    
    func configure(profileType: ProfileType) {
        if profileType == .profile {
            configureMyProfileCell()
        } else if profileType == .avatar {
            configureAvatarCell()
        }
    }
    
    func configureMyProfileCell() {
        nameLabel.text = UserService.singleton.getFirstLastName()
        usernameLabel.text = UserService.singleton.getUsername()
        profileImageView.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
        verifiedImageView.isHidden = false
        verifiedImageView.image = UserService.singleton.isVerified() ? UIImage(systemName: "checkmark.seal.fill") : nil
    }
    
    func configureAvatarCell() {
        nameLabel.text = "avatar"
        usernameLabel.text = UserService.singleton.getUsername()
        profileImageView.becomeProfilePicImageView(with: UserService.singleton.getSilhouette())
        verifiedImageView.isHidden = true
        verifiedImageView.image = UserService.singleton.isVerified() ? UIImage(systemName: "checkmark.seal.fill") : nil
    }
}
