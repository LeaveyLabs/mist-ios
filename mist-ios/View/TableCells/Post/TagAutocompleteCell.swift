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
    
    var phoneImageView: UIImageView!
    
    //flag
    var isContact: Bool = false
    
    override func setupSubviews() {
        super.setupSubviews()
        tagAutocompleteSetup()
        tagAutocompletePrepareForReuse()
    }
    
    func tagAutocompleteSetup() {
        phoneImageView = UIImageView(image: TagAutocompleteCell.contactImage)
        addSubview(phoneImageView)
        phoneImageView.tintColor = .gray
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        tagAutocompletePrepareForReuse()
    }
    
    func tagAutocompletePrepareForReuse() {
        isContact = false
        separatorLine.isHidden = true
        textLabel?.font = UIFont(name: Constants.Font.Medium, size: 14)
        detailTextLabel?.font = UIFont(name: Constants.Font.Medium, size: 14)
        detailTextLabel?.textColor = .gray
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        fixImageAndLabelLayout()
    }
    
    // i can't figure out how to use these insets properly... there's too much customization provided by default by the autocomplete cell. i just override it below
    // imageViewEdgeInsets = .init(top: 5, left: -10, bottom: 0, right: 0)
    func fixImageAndLabelLayout() {
        layoutPhoneImageSubvew()
        
        guard let imageView = imageView, let image = imageView.image else { return } //don't run the following for the default labels
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
            
            phoneImageView.frame.origin.x -= widthToShiftOver + 15 // a tad more to the left
        } else {
            imageView.frame.size = .init(width: 40, height: 40)
            let name = textLabel?.text?.components(separatedBy: .whitespacesAndNewlines)
            imageView.addInitials(first: String(name?.first?.uppercased().first ?? Character.init("")),
                                  second: String(name?.last?.uppercased().first ?? Character.init("")),
                                  font: UIFont(name: Constants.Font.Heavy, size: 16)!,
                                  textColor: .black,
                                  backgroundColor: .systemGray6)
        }
    }
    
    func layoutPhoneImageSubvew() {
        if isContact {
            phoneImageView.isHidden = false
            phoneImageView.frame = .init(x: detailTextLabel!.frame.origin.x,
                                         y: detailTextLabel!.frame.origin.y + 1,
                                         width: 14,
                                         height: 14)
            detailTextLabel?.frame.origin.x += 17 //must come after the above line
        } else {
            phoneImageView.isHidden = true
        }
    }
    
}
