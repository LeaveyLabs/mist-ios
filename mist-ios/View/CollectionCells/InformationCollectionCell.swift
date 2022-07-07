//
//  InformationCollectionCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/6/22.
//

import UIKit

class InformationCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var infoLabel: UILabel!
        
    open func configure(with messageKitInfo: MessageKitInfo) {
        infoLabel.text = messageKitInfo.infoMessage
    }

}
