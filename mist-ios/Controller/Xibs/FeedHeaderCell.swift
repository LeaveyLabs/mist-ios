//
//  FeedHeaderCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class FeedHeaderCell: UITableViewCell {
    
    @IBOutlet weak var feedHeaderLabel: UILabel!
    var feedType: FeedType?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
