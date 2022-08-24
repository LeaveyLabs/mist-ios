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

extension AutocompleteTableView {
    
    var heightBetweenInputBarAndNavBar: CGFloat? {
//        return CGFloat(maxVisibleRows) //this method results in slightly off sizing for large iphones
        
        guard let inputAccessoryView = superview?.superview else {
            return nil
        }
        guard
            let navBarHeight = self.parentViewController()?.navigationController?.navigationBar.frame.height,
            let statusBarHeight = self.parentViewController()?.window?.windowScene?.statusBarManager?.statusBarFrame.height
        else { return nil }

        let inputBarHeight = CGFloat(maxVisibleRows)
        return inputAccessoryView.frame.maxY - 1 - navBarHeight - inputBarHeight  - statusBarHeight
    }
    
    open override var intrinsicContentSize: CGSize {
//        return
        //original method:
//        let rows = numberOfRows(inSection: 0) < maxVisibleRows ? numberOfRows(inSection: 0) : maxVisibleRows
//        return CGSize(width: super.intrinsicContentSize.width, height: CGFloat(rows) * rowHeight)
        
        guard let height = heightBetweenInputBarAndNavBar else {
            print("ERROR: Could not update intrinsic content size of autcompletetableview correctly")
            let rows = 4
            return CGSize(width: super.intrinsicContentSize.width, height: CGFloat(rows) * rowHeight)
        }
        return CGSize(width: super.intrinsicContentSize.width, height: height)
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
    }

}

class CommentAutocompleteManager: AutocompleteManager {
    
//    let topLineView = UIView()
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    let placeholderLabel = UILabel(frame: .init(x: 0, y: 0, width: 250, height: 30))
    
    override init(for textView: UITextView) {
        super.init(for: textView)
        register(prefix: "@", with: Comment.tagInputAttributes)
        defaultTextAttributes = Comment.normalInputAttributes
        appendSpaceOnCompletion = true
        keepPrefixOnCompletion = true
        deleteCompletionByParts = false
        tableView.rowHeight = 60
        tableView.register(TagAutocompleteCell.self, forCellReuseIdentifier: TagAutocompleteCell.reuseIdentifier)
        placeholderLabel.font = UIFont(name: Constants.Font.Medium, size: 16)
        placeholderLabel.textColor = Constants.Color.mistBlack
        
//        tableView.backgroundColor = .red
        
//        topLineView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0.5)
//        topLineView.backgroundColor = .systemGray2
        
        setupSubviews()
    }
    

    func setupSubviews() {
//        tableView.addSubview(topLineView)
        tableView.addSubview(activityIndicator)
        tableView.addSubview(placeholderLabel)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTableViewSubviews()
    }
    
    func updateTableViewSubviews() {
        activityIndicator.frame.origin.x = tableView.frame.width - 45
//        activityIndicator.frame.origin.y = tableView.contentOffset.y + 20 for some reason, this does not work when the autocompleteTableView readjusts updates while inputting
        activityIndicator.frame.origin.y = tableView.frame.minY + 20 //stay at top right

//        placeholderLabel.frame.origin.y = tableView.contentOffset.y + 15 same as above
        placeholderLabel.frame.origin.y = tableView.frame.minY + 15
        placeholderLabel.frame.origin.x = 20
        
        placeholderLabel.isHidden = tableView.numberOfRows(inSection: 0) > 0
        
//        topLineView.frame.origin.y = tableView.contentOffset.y
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
        super.tableView.layoutIfNeeded() //make sure the frame is updated before updating table view's subviews
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

