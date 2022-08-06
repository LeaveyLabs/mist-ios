//
//  TagAutocompleteCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/6/22.
//

import Foundation
import InputBarAccessoryView //dependency of MessageKit. If we remove MessageKit, we should install this package independently

class TagAutocompleteCell: AutocompleteCell {
    
    static let contactImage = UIImage(systemName: "phone")!
    
    override func setupSubviews() {
        super.setupSubviews()
        tagAutocompleteSetup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        tagAutocompleteSetup()
    }
    
    func tagAutocompleteSetup() {
        separatorLine.isHidden = true
        textLabel?.font = UIFont(name: Constants.Font.Medium, size: 15)
        detailTextLabel?.font = UIFont(name: Constants.Font.Medium, size: 13)
        detailTextLabel?.textColor = .gray
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        fixImageAndLabelLayout()
    }
    
    // i can't figure out how to use these insets properly... there's too much customization provided by default by the autocomplete cell. i just override it below
    // imageViewEdgeInsets = .init(top: 5, left: -10, bottom: 0, right: 0)
    func fixImageAndLabelLayout() {
        if let imageView = imageView, let image = imageView.image {
            textLabel?.font = UIFont(name: Constants.Font.Heavy, size: 15)
            textLabel?.frame.origin.y += 4
            detailTextLabel?.frame.origin.y -= 1
            
            if image != TagAutocompleteCell.contactImage {
                let initialImageViewWidth = imageView.frame.size.width
                imageView.contentMode = .scaleAspectFill
                imageView.frame.size = .init(width: 40, height: 40)
                imageView.layer.cornerRadius = imageView.frame.size.height / 2
                imageView.layer.cornerCurve = .continuous
                imageView.clipsToBounds = true
                
                let widthToShiftOver = initialImageViewWidth - 40
                textLabel?.frame.origin.x -= widthToShiftOver + 15
                detailTextLabel?.frame.origin.x -= widthToShiftOver + 15
                imageView.frame.origin.x -= 7
                imageView.frame.origin.y += 6
                    
            } else {
                imageView.layer.cornerRadius = 0
            }
        }
    }
    
}
