//
//  MyProfileTableViewCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/10.
//

import UIKit

class MyProfileCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var verifiedImageView: UIImageView!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        usernameLabel.text = UserService.singleton.getUsername()
        nameLabel.text = UserService.singleton.getFirstLastName()
        profileImageView.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
        verifiedImageView.image = UserService.singleton.isVerified() ? UIImage(systemName: "checkmark.seal.fill") : nil
    }
    
    override func prepareForReuse() {
        usernameLabel.text = UserService.singleton.getUsername()
        nameLabel.text = UserService.singleton.getFirstLastName()
        profileImageView.image = UserService.singleton.getProfilePic()
    }
}
