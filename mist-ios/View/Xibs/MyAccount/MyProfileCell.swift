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
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        usernameLabel.text = UserService.singleton.getUsername()
        nameLabel.text = UserService.singleton.getFirstLastName()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.image = UserService.singleton.getProfilePic()
        profileImageView.becomeRound()
    }
    
    override func prepareForReuse() {
        usernameLabel.text = UserService.singleton.getUsername()
        nameLabel.text = UserService.singleton.getFirstLastName()
        profileImageView.image = UserService.singleton.getProfilePic()
    }
}
