//
//  MistboxKeywordTableViewCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import UIKit
import WSTagsField

protocol TagsViewDelegate {
    func didUpdateTags(tags: [String])
}

class TagsViewCell: UITableViewCell {
    
    static var RandomPlacehodler: String {
        return ["tall", "puppy", "starbucks", "jansport", "tennis", "brunette", "blonde", "carhartt", "mccarthy", "dulce", "doheny", "pardee", "csci103", "writ150", "gold", "cat", "sunglasses", "beanie", "football", "basketball", ].randomElement()!
    }
    //we should have a "suggestions" area

    static var MaxTagCount = 5
    
    var delegate: TagsViewDelegate!
    let tagsField = WSTagsField()
    var keywords = [String]()
    let tagsCountLabel = UILabel()
    
    func configure(existingKeywords: [String], delegate: TagsViewDelegate) {
//        keywords = existingKeywords
        tagsField.addTags(existingKeywords)
//        keywords.forEach { word in
//            tagsField.addTag(word)
//        }
        updateTagsCount()
        
        self.delegate = delegate
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tagsField.textField.becomeFirstResponder()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = Constants.Color.offWhite
        separatorInset = .init(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        setupTagsField()
        setupTagsCountLabel()
    }
    
    func setupTagsCountLabel() {
        tagsCountLabel.textAlignment = .right
        tagsCountLabel.translatesAutoresizingMaskIntoConstraints = false
        tagsCountLabel.frame = .init(x: 0, y: 0, width: 100, height: 40)
        tagsCountLabel.textColor = Constants.Color.mistBlack
        tagsCountLabel.font = UIFont(name: Constants.Font.Roman, size: 20)
        contentView.addSubview(tagsCountLabel)
        NSLayoutConstraint.activate([
            tagsCountLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 18),
            tagsCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tagsCountLabel.heightAnchor.constraint(equalToConstant: 30),
            tagsCountLabel.widthAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    func updateTagsCount() {
        tagsCountLabel.text = String(keywords.count) + "/" + String(TagsViewCell.MaxTagCount)
    }
    
    func setupTagsField() {
        tagsField.applyLightMediumShadow()
        tagsField.placeholderAlwaysVisible = true
        tagsField.backgroundColor = .white
        tagsField.layer.cornerCurve = .continuous
        tagsField.layer.cornerRadius = 10
        tagsField.contentInset = UIEdgeInsets(top: 20, left: 15, bottom: 15, right: 15)
        tagsField.layoutMargins = UIEdgeInsets(top: 4, left: 12, bottom: 2, right: 10) //the size of the color behind the tag
        tagsField.font = UIFont(name: Constants.Font.Medium, size: 22) //when the font is larger than this, the bottoms of g/j/q get cut off...
        tagsField.placeholderFont = UIFont(name: Constants.Font.Medium, size: 22)
        tagsField.placeholder = TagsViewCell.RandomPlacehodler
        tagsField.spaceBetweenLines = 25
        tagsField.spaceBetweenTags = 10
        
        tagsField.tintColor = Constants.Color.mistPink
        tagsField.textField.tintColor = Constants.Color.mistLilac
        tagsField.textColor = Constants.Color.mistBlack
        //YOOO Shadow behind the tag?
        tagsField.selectedColor = Constants.Color.mistLilac
        tagsField.selectedTextColor = .white
        
        tagsField.isDelimiterVisible = false
        tagsField.placeholderColor = Constants.Color.mistLilac
        tagsField.placeholderAlwaysVisible = true
        tagsField.keyboardAppearance = .default
        tagsField.acceptTagOption = [.return, .comma, .space]
        tagsField.shouldTokenizeAfterResigningFirstResponder = true

        // Events
        tagsField.onDidAddTag = { field, tag in
            self.keywords.append(tag.text)
            self.didUpdateTag()
        }

        tagsField.onDidRemoveTag = { field, tag in
            self.keywords.removeFirstAppearanceOf(object: tag.text)
            self.didUpdateTag()
        }

        tagsField.onDidChangeText = { _, text in
            print("DidChangeText")
        }

        tagsField.onDidChangeHeightTo = { _, height in
            print("HeightTo", height)
        }

        tagsField.onValidateTag = { tag, tags in
            guard
                tags.count < TagsViewCell.MaxTagCount,
                !tags.contains(where: { $0.text.uppercased() == tag.text.uppercased() })
            else { return false }
            return true
        }

        print("List of Tags Strings:", tagsField.tags.map({$0.text}))
        
        tagsField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tagsField)
        NSLayoutConstraint.activate([
            tagsField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17),
            tagsField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 17),
            tagsField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -17),
            contentView.bottomAnchor.constraint(equalTo: tagsField.bottomAnchor, constant: 17),
            tagsField.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
        
    }
    
    func didUpdateTag() {
        delegate?.didUpdateTags(tags: self.keywords) //must use delegate? because it might be optional
        updateTagsCount()
        tagsField.placeholder = self.keywords.count < TagsViewCell.MaxTagCount ? TagsViewCell.RandomPlacehodler : ""
        tagsField.tagViews.forEach { view in
            view.applyLightMediumShadow()
            view.cornerRadius = 8
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}


//could always subclass tagsfield to prevent more words after 5
