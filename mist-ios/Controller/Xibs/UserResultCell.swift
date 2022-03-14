//
//  UserResultsCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class UserResultCell: UITableViewCell {
    
    var parentVC: UIViewController!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureUserCell(profile: Profile, parent: UIViewController) {
        parentVC = parent
        nameLabel.text = profile.first_name + " " +  profile.last_name
        usernameLabel.text = profile.username
        profileImageView.image = UIImage(named: "adam")
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height / 2
        profileImageView.layer.cornerCurve = .continuous
    }
    
}
