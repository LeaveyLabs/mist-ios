//
//  ToggleSettingsCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/20/22.
//

import UIKit

class ToggleSettingsCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var accessoryIndicatorBackgroundView: UIView! //for notifications
    var isToggled = false
        
    override func awakeFromNib() {
        super.awakeFromNib()
        accessoryIndicatorBackgroundView.roundCornersViaCornerRadius(radius: 10)
        selectionStyle = .default
        selectedBackgroundView = UIView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func configure(labelText: String) {
        titleLabel.text = labelText
        accessoryIndicatorBackgroundView.backgroundColor = .clear
    }
    
    func setToggled(_ toggled: Bool) {
        isToggled = toggled
        accessoryIndicatorBackgroundView.backgroundColor = toggled ? Constants.Color.mistLilac : .clear
    }
    
    //this shit doenst work
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//        accessoryIndicatorBackgroundView.backgroundColor = selected ? Constants.Color.mistLilac : .clear
//    }
    
}
