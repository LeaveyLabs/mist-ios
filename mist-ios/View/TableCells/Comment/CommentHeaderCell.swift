//
//  CommentCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import UIKit

class CommentHeaderCell: UITableViewCell {
    
    //MARK: - Properties

    //UI
    @IBOutlet weak var headerLabel: UILabel!
    
    //MARK: - Setup
    
    func configure(commentCount: Int) {
        self.separatorInset = .init(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        if commentCount > 99 {
            headerLabel.text = "99+ Comments"
        } else {
            headerLabel.text = String(commentCount) + " Comments"
        }
    }
}
