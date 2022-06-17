//
//  ResultsTableViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

class SearchSuggestionsTableViewController: UITableViewController {
    
    //MARK: - Properties
    
    //Search
    var searchText = ""
    var wordResults = [Word]()
    
    //Map Search
    private var searchCompleter: MKLocalSearchCompleter?
    var completerResults: [MKLocalSearchCompletion]?
    
    var oneSearchAlreadyFinished: Bool = false //a flag to determine when both async searches have finished
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCells()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startProvidingCompletions()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopProvidingCompletions()
    }
    
    private func startProvidingCompletions() {
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter?.delegate = self
        searchCompleter?.resultTypes = [.pointOfInterest, .address, .query]
        searchCompleter?.region = MKCoordinateRegion(MKMapRect.world) //we want the user to be able to see search suggestions from all over the world
    }
    
    private func stopProvidingCompletions() {
        searchCompleter = nil
    }
    
    private func registerCells() {
        tableView.register(SuggestedCompletionTableViewCell.self, forCellReuseIdentifier: SuggestedCompletionTableViewCell.reuseID)
        let nib = UINib(nibName: Constants.SBID.Cell.WordResult, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: Constants.SBID.Cell.WordResult)
    }
}

//MARK: - Public interface

extension SearchSuggestionsTableViewController {
    
    func updatePlacemark(_ placemark: CLPlacemark?, boundingRegion: MKCoordinateRegion) {
        searchCompleter?.region = boundingRegion
    }
    
}

// MARK: - UITableViewDataSource

extension SearchSuggestionsTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !searchText.isEmpty else { return "" }
        let resultType = MapSearchResultType.init(rawValue: section)!
        return resultType.sectionName
    }
        
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let resultType = MapSearchResultType.init(rawValue: section)!
        switch resultType {
        case .containing:
            return wordResults.count
        case .nearby:
            if searchText.isEmpty {
                return 0
            } else {
                return max(completerResults?.count ?? 0, 1) //return 1 "no results" cell if completerResults is nil
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultType = MapSearchResultType.init(rawValue: indexPath.section)!
        switch resultType {
        case .containing:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.WordResult, for: indexPath) as! WordResultCell
            cell.imageView?.image = UIImage(systemName: "magnifyingglass")
            cell.configureWordCell(word: wordResults[indexPath.row], searchText: searchText)
            if wordResults[indexPath.row].occurrences == 0 {
                cell.accessoryType = .none
                cell.isUserInteractionEnabled = false
            }
            return cell
        case .nearby:
            let cell = tableView.dequeueReusableCell(withIdentifier: SuggestedCompletionTableViewCell.reuseID, for: indexPath)
            cell.imageView?.image = UIImage(systemName: "mappin.circle")
            if let results = completerResults, !results.isEmpty {
                let suggestion = results[indexPath.row]
                cell.textLabel?.text = suggestion.title
                cell.detailTextLabel?.text = suggestion.subtitle
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "No results"
                cell.detailTextLabel?.text = ""
                cell.accessoryType = .none
                cell.isUserInteractionEnabled = false
            }
            return cell
        }
    }
    
    //Not being used at the moment
    private func createHighlightedString(text: String, rangeValues: [NSValue]) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.backgroundColor: UIColor.white ]
        let highlightedString = NSMutableAttributedString(string: text)
        
        // Each `NSValue` wraps an `NSRange` that can be used as a style attribute's range with `NSAttributedString`.
        let ranges = rangeValues.map { $0.rangeValue }
        ranges.forEach { (range) in
            highlightedString.addAttributes(attributes, range: range)
        }
        
        return highlightedString
    }
}

//MARK: - MKLocalSearchCompleterDelegate

extension SearchSuggestionsTableViewController: MKLocalSearchCompleterDelegate {
    
    /// - Tag: QueryResults
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // As the user types, new completion suggestions are continuously returned to this method.
        // Overwrite the existing results, and then refresh the UI with the new results.
        
        completerResults = completer.results
        completerResults?.forEach({ completion in
            //make a call to our personal data base for an icon & number of posts nearby
        })
        
        handleFinishedSearch()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        
    }
}

//MARK: - UISearchResultsUpdating

extension SearchSuggestionsTableViewController: UISearchResultsUpdating {
    
    //Update the filtered array based on the search text.
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        self.searchText = searchText
        guard !searchText.isEmpty else {
            //User might have typed a word into the searchbar, but then deleted it. so lets reset the live results.
            //We dont reset live results normally because we want the previous search results to stay visible
            //until the new db call returns.
            completerResults = []
            wordResults = []
            tableView.reloadData()
            return
        }
                
        //Nearby Seaarch
        // Ask `MKLocalSearchCompleter` for new completion suggestions based on the change in the text entered in `UISearchBar`.
        searchCompleter?.queryFragment = "" //when the user toggles the selected scope, the query fragment has not actually changed, so we must incorrectly and then recorrectly set it to force a new search
        searchCompleter?.queryFragment = searchText
        
        //Containing search
        Task {
            do {
                let allResults = try await WordAPI.fetchWords(text: searchText)
                handleNewWordResults(allResults)
                handleFinishedSearch()
            } catch {
                CustomSwiftMessages.showError(errorDescription: error.localizedDescription)
            }
        }
    }
    
    func handleNewWordResults(_ allResults: [Word]) {
        wordResults = Array(allResults.sorted(by: { wordOne, wordTwo in
            wordOne.occurrences > wordTwo.occurrences
        }).prefix(3))
        
        //TODO: handle where user changed the text after initiating the search
        
        let userSearchedWordIndex = wordResults.firstIndex { word in
            word.text == searchText
        }
        if let index = userSearchedWordIndex {
            //if allresults contains current word, make it appear first.'
            let userSearchedWordResult = wordResults.remove(at: index)
            wordResults.insert(userSearchedWordResult, at: 0)
        } else {
            //otherwise, replace the third word result with a word result with 0 results that's unclickable
            if !wordResults.isEmpty {
                wordResults.removeLast()
            }
            wordResults.insert(Word(text: searchText, occurrences: 0), at: 0)
        }
    }
    
    func handleFinishedSearch() {
        if !oneSearchAlreadyFinished {
            oneSearchAlreadyFinished = true
            return
        }
        
        if !searchText.isEmpty { //Check that the user didn't delete the search query before it finished
            tableView.reloadData()
        }
    }
    
}

//MARK: - Suggestion TableViewCell

private class SuggestedCompletionTableViewCell: UITableViewCell {
    
    static let reuseID = "SuggestedCompletionTableViewCellReuseID"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
