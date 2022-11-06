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
    let loadingIndicator = UIActivityIndicatorView(style: .medium)

    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    func commonInit() {
        loadingIndicator.frame = imageView!.frame
        loadingIndicator.isHidden = true
        imageView?.addSubview(loadingIndicator)
        loadingIndicator.color = Constants.Color.mistBlack
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWordCell(word: Word, wrapperWords: [String]) {
        imageView?.image = UIImage(systemName: "magnifyingglass")
        print("WORDS", wrapperWords, word)
        
        accessoryLabel.text = ""
        titleLabel.text = ""
        for i in 0..<wrapperWords.count {
            titleLabel.text! += wrapperWords[i] + ", "
        }
        titleLabel.text! += word.text
//        subtitleLabel.text = ""
//        accessoryLabel.text = word.occurrences > 99 ? "99+" : String(word.occurrences)
        accessoryType = .disclosureIndicator
        isUserInteractionEnabled = true
    }
    
    func configureNoWordResultsCell() {
        imageView?.image = UIImage(systemName: "magnifyingglass")
        titleLabel.text = "no results"
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
        titleLabel.text = "no results"
        subtitleLabel.text = ""
        accessoryLabel.text = ""
        accessoryType = .none
        isUserInteractionEnabled = false
    }
    
    func startLoadingIcon() {
        imageView?.image = nil
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
    }
    
    func stopLoadingIcon() {
        imageView?.image = UIImage(systemName: "mappin.circle")
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
    }
    
}
