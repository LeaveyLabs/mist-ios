//
//  CommentAutocompleteManager.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/6/22.
//

import Foundation
import InputBarAccessoryView //dependency of MessageKit. If we remove MessageKit, we should install this package independently


//"text" is what gets autocompleted: that will be the username
//"queryName" is what appears on the tableView list when selecting
enum AutocompleteContext: String {
    case id, numberPretty, numberE164, pic, queryName
//    case id, number, pic, username, name
}


class CommentAutocompleteManager: AutocompleteManager {
    
    let topLineView = UIView()
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    let resultsCountLabel = UILabel(frame: .init(x: 0, y: 0, width: 60, height: 30))
    
    static let tagTextAttributes: [NSAttributedString.Key : Any] = [
//        .font: UIFont.preferredFont(forTextStyle: .body),
        .font: UIFont(name: Constants.Font.Medium, size: 17)!,
        .foregroundColor: UIColor.init(hex: "#1464a6"),
//        .backgroundColor: UIColor.red.withAlphaComponent(0.1)
    ]
    
    override init(for textView: UITextView) {
        super.init(for: textView)
        register(prefix: "@", with: CommentAutocompleteManager.tagTextAttributes)
        appendSpaceOnCompletion = true
        keepPrefixOnCompletion = true
        deleteCompletionByParts = false
        tableView.rowHeight = 60
        tableView.register(TagAutocompleteCell.self, forCellReuseIdentifier: TagAutocompleteCell.reuseIdentifier)
        setupSubviews()
        //not worrying about this for now
//        tableView.addSubview(resultsCountLabel)
//        resultsCountLabel.font = UIFont(name: Constants.Font.Medium, size: 12)
//        resultsCountLabel.textColor = .gray
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
        activityIndicator.frame.origin.y = tableView.contentOffset.y + 20 + tableView.frame.height - tableView.rowHeight //stay at the bottom right
//        resultsCountLabel.frame.origin.y = tableView.contentOffset.y + 13 + tableView.frame.height - 50 //stay at bottom right
        
//        resultsCountLabel.text = String(tableView.numberOfRows(inSection: 0)) + " results"
//        resultsCountLabel.isHidden = tableView.numberOfRows(inSection: 0) > 0 && activityIndicator.isAnimating == false
    }
    
    override func reloadData() {
        //From "super.reloadData()":
//        var delimiterSet = autocompleteDelimiterSets.reduce(CharacterSet()) { result, set in
//            return result.union(set)
//        }
//        let query = textView?.find(prefixes: autocompletePrefixes, with: delimiterSet)
//        print(query)
        ///the problem is that query is returning "a  " as its word
        ///because there is a word that's found, and because there is no session existing, a new session is created
        ///the solution: query should be returning nil.
        ///but also, it's not worth overriding all the autocompletemanager text for this
        ///we are currently solving by simply cancelling a newly start session upon faulty text
        
        super.reloadData()
        updateTableViewSubviews()
    }
    
    
    
    /// Overriding currentAutocompleteOptions because we need them to properly override didSelectRowAt and because the person who wrote AutocompleteManager unprudently made its access level private
    var currentAutocompleteOptions: [AutocompleteCompletion] {
        
        guard let session = currentSession, let completions = dataSource?.autocompleteManager(self, autocompleteSourceFor: session.prefix) else { return [] } 
        guard !session.filter.isEmpty else { return completions }
        return completions.filter { completion in
            return filterBlock(session, completion)
        }
    }
    
    //Prevent placeholder cells from being selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let session = currentSession else { return }
        guard session.completion?.context != nil else { return } //prevent placeholder cells from being selected
        session.completion = currentAutocompleteOptions[indexPath.row]
        autocomplete(with: session)
    }
    
}

import UIKit

public extension UITextView {
    
    func find(prefix: String, with delimiterSet: CharacterSet) -> Match? {
        guard !prefix.isEmpty else { return nil }
        guard let caretRange = self.caretRange else { return nil }
        guard let cursorRange = Range(caretRange, in: text) else { return nil }
        
        let leadingText = text[..<cursorRange.upperBound]
        var prefixStartIndex: String.Index!
        for (i, char) in prefix.enumerated() {
            guard let index = leadingText.lastIndex(of: char) else { return nil }
            if i == 0 {
                prefixStartIndex = index
            } else if index.utf16Offset(in: leadingText) == prefixStartIndex.utf16Offset(in: leadingText) + 1 {
                prefixStartIndex = index
            } else {
                return nil
            }
        }

        let wordRange = prefixStartIndex..<cursorRange.upperBound
        let word = leadingText[wordRange]
        
        //MY ADDITION WHICH THE SAMPLE CODE LEAVES OUT
        //Unfortunately, re-extending the function here does not override the original extension, so this does not change the unideal behavior
            //Ensure the text does not contain any of the delimiter set
        print(word.rangeOfCharacter(from: delimiterSet) as Any)
        guard word.rangeOfCharacter(from: delimiterSet) == nil else {
            print("RETURNING NIL BC DELIMITTER")
            return nil
        }
        
        let location = wordRange.lowerBound.utf16Offset(in: leadingText)
        let length = wordRange.upperBound.utf16Offset(in: word) - location
        let range = NSRange(location: location, length: length)
        
        return (String(prefix), String(word), range)
    }
    
}

