//
//  PostResultsCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

class SearchResultCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var accessoryLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWordCell(word: Word) {
        imageView?.image = UIImage(systemName: "magnifyingglass")
        titleLabel.text = word.text
//        subtitleLabel.text = ""
        accessoryLabel.text = String(word.occurrences)
        accessoryType = .disclosureIndicator
        isUserInteractionEnabled = true
    }
    
    func configureNoWordResultsCell() {
        imageView?.image = UIImage(systemName: "magnifyingglass")
        titleLabel.text = "No results"
//        subtitleLabel.text = ""
        accessoryLabel.text = ""
        accessoryType = .none
        isUserInteractionEnabled = false
    }
    
    //Not in use right now
    
    func configureLocalSearchCompletionCell(suggestion: MKLocalSearchCompletion) {
        imageView?.image = UIImage(systemName: "mappin.circle")
        titleLabel.text = suggestion.title
        subtitleLabel.text = suggestion.subtitle
        accessoryLabel.text = ""
        accessoryType = .disclosureIndicator
        isUserInteractionEnabled = true
    }
        
    func configureNoCompleterResultsCell() {
        imageView?.image = UIImage(systemName: "mappin.circle")
        titleLabel.text = "No results"
        subtitleLabel.text = ""
        accessoryLabel.text = ""
        accessoryType = .none
        isUserInteractionEnabled = false
    }
}