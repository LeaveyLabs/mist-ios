//
//  CollectibleCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/25/22.
//

import Foundation
import UIKit

class CollectibleCell: UITableViewCell {
    
    var collectibleView: CollectibleView!
    
    //MARK: - Public Interface
    
    func configure(collectibleType: Int, delegate: CollectibleViewDelegate) {
        UIView.performWithoutAnimation { //this is necessary with our current approach to the input accessory view and keyboardlayoutguide. tableview ends up getting animated, but that creates weird animations for the cells, too. so dont allow the cell updates to animate
            collectibleView.configureForCollectible(collectibleType: collectibleType, delegate: delegate, onNewPost: false)
        }
    }
    
    //MARK: - Suggestion TableViewCell

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: Constants.SBID.Cell.Post)
        
        selectionStyle = .none
        separatorInset = .init(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        
        collectibleView = CollectibleView()
        collectibleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectibleView)
        NSLayoutConstraint.activate([
            collectibleView.heightAnchor.constraint(equalToConstant: 80),
            collectibleView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -30),
            collectibleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0),
            collectibleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            collectibleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
