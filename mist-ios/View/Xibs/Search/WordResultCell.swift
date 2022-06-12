//
//  PostResultsCell.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class WordResultCell: UITableViewCell {
    
    var parentVC: UIViewController!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var occurencesLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWordCell(word: Word, parent: UIViewController) {
        parentVC = parent
        wordLabel.text = word.text
        occurencesLabel.text = String(word.occurrences)
    }
    
    
}
