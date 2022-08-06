//
//  CommentAutocompleteManager.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/6/22.
//

import Foundation
import InputBarAccessoryView //dependency of MessageKit. If we remove MessageKit, we should install this package independently

enum AutocompleteContext: String {
    case id, number, pic, username, name
}

class CommentAutocompleteManager: AutocompleteManager {
    
    let topLineView = UIView()
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    let resultsCountLabel = UILabel(frame: .init(x: 0, y: 0, width: 60, height: 30))
    
    static let tagTextAttributes: [NSAttributedString.Key : Any] = [
//        .font: UIFont.preferredFont(forTextStyle: .body),
        .font: UIFont(name: Constants.Font.Heavy, size: 17)!,
        .foregroundColor: UIColor.black,
//        .backgroundColor: UIColor.red.withAlphaComponent(0.1)
    ]
    
    override init(for textView: UITextView) {
        super.init(for: textView)
        register(prefix: "@", with: CommentAutocompleteManager.tagTextAttributes)
        appendSpaceOnCompletion = true
        keepPrefixOnCompletion = true
        deleteCompletionByParts = false
        tableView.rowHeight = 52
        tableView.register(TagAutocompleteCell.self, forCellReuseIdentifier: TagAutocompleteCell.reuseIdentifier)
        
        filterBlock = { session, completion in
            return true //we apply our own filters, so assume that every autocompletion is valid
        }
        setupSubviews()
        //not worrying about this for now
//        tableView.addSubview(resultsCountLabel)
//        resultsCountLabel.font = UIFont(name: Constants.Font.Medium, size: 12)
//        resultsCountLabel.textColor = .gray
        
        //The following two aren't actually needed because of our own checks
//        autocompleteManager.register(delimiterSet: .whitespacesAndNewlines)
//        autocompleteManager.maxSpaceCountDuringCompletion = 1
    }
    

    func setupSubviews() {
        topLineView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0.5)
        topLineView.backgroundColor = .systemGray2
        tableView.addSubview(topLineView)
        tableView.addSubview(activityIndicator)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTableViewSubviews()
    }
    
    func updateTableViewSubviews() {
        activityIndicator.frame.origin.x = tableView.frame.width - 35
//        resultsCountLabel.frame.origin.x = tableView.frame.width - 60 //better to have a constraint....

        topLineView.frame.origin.y = tableView.contentOffset.y
        activityIndicator.frame.origin.y = tableView.contentOffset.y + 13 + tableView.frame.height - 50 //stay at the bottom right
//        resultsCountLabel.frame.origin.y = tableView.contentOffset.y + 13 + tableView.frame.height - 50 //stay at bottom right
        
//        resultsCountLabel.text = String(tableView.numberOfRows(inSection: 0)) + " results"
//        resultsCountLabel.isHidden = tableView.numberOfRows(inSection: 0) > 0 && activityIndicator.isAnimating == false
    }
    
    override func reloadData() {
        super.reloadData()
        updateTableViewSubviews()
    }
    
    //Prevent placeholder cells from being selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let session = currentSession else { return }
        guard let completions = dataSource?.autocompleteManager(self, autocompleteSourceFor: session.prefix) else { return }
        session.completion = completions[indexPath.row]
        guard session.completion?.context != nil else { return } //prevent placeholder cells from being selected
        autocomplete(with: session)
    }
}
