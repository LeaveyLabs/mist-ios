//
//  PostResultsCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class SearchResultCell: UITableViewCell {
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var occurencesLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWordCell(word: Word) {
        commonConfigure()
        wordLabel.text = word.text
        occurencesLabel.text = String(word.occurrences)
        accessoryType = .disclosureIndicator
        isUserInteractionEnabled = true
    }
    
    func configureNoResultsCell() {
        commonConfigure()
        wordLabel.text = "No results"
        occurencesLabel.text = ""
        accessoryType = .none
        isUserInteractionEnabled = false
    }
    
    func commonConfigure() {
        imageView?.image = UIImage(systemName: "magnifyingglass")
    }
}
