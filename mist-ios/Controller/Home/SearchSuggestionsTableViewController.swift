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
    private var searchText = ""
    private var didOneSearchAlreadyFinish: Bool = false //a flag to determine when both async searches have finished
    
    //Text Search
    var wordResults = [Word]()
    
    //Map Search
    private var searchCompleter = MKLocalSearchCompleter()
    var completerResults = [MKLocalSearchCompletion]()
    
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCells()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.contentInset.top -= self.view.safeAreaInsets.top - 20 //needed bc auto content inset adjustment behavior isn't reflecing safeareainsets for some reason
    }
    
    private func registerCells() {
        tableView.register(SuggestedCompletionTableViewCell.self, forCellReuseIdentifier: SuggestedCompletionTableViewCell.reuseID)
        let nib = UINib(nibName: Constants.SBID.Cell.SearchResult, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: Constants.SBID.Cell.SearchResult)
    }
}

//MARK: - Public Interface

extension SearchSuggestionsTableViewController {
    
    func startProvidingCompletions(for region: MKCoordinateRegion) {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.pointOfInterest, .address]
        searchCompleter.region = region
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
    
    //Fix font
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont(name: Constants.Font.Medium, size: 15)
    }
            
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let resultType = MapSearchResultType.init(rawValue: section)!
        if searchText.isEmpty { return 0 }
        switch resultType {
        case .containing:
            return max(wordResults.count, 1) //return 1 "no results" cell
        case .nearby:
            return max(completerResults.count + 1, 1) //return 1 "no results" cell. +1 is for the current search string
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let resultType = MapSearchResultType.init(rawValue: indexPath.section)!
        switch resultType {
        case .containing:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.SearchResult, for: indexPath) as! SearchResultCell
            if !wordResults.isEmpty {
                cell.configureWordCell(word: wordResults[indexPath.row])
            } else {
                cell.configureNoWordResultsCell()
            }
            cell.textLabel?.font = UIFont(name: Constants.Font.Medium, size: 16)
            cell.subtitleLabel?.font = UIFont(name: Constants.Font.Medium, size: 12)
            return cell
        case .nearby:
            let cell = tableView.dequeueReusableCell(withIdentifier: SuggestedCompletionTableViewCell.reuseID, for: indexPath)
            cell.imageView?.image = UIImage(systemName: "mappin.circle")
            if !completerResults.isEmpty {
                if indexPath.row == 0 {
                    cell.textLabel?.text = searchText // + "\""
                    cell.detailTextLabel?.text = "Nearby search"
                    cell.accessoryType = .disclosureIndicator
                    cell.isUserInteractionEnabled = true
                } else {
                    let suggestion = completerResults[indexPath.row-1]
                    cell.textLabel?.text = suggestion.title
                    cell.detailTextLabel?.text = suggestion.subtitle
                    cell.accessoryType = .disclosureIndicator
                    cell.isUserInteractionEnabled = true
                }
            } else {
                cell.textLabel?.text = "No results"
                cell.detailTextLabel?.text = ""
                cell.accessoryType = .none
                cell.isUserInteractionEnabled = false
            }
            cell.textLabel?.font = UIFont(name: Constants.Font.Medium, size: 16)
            cell.detailTextLabel?.font = UIFont(name: Constants.Font.Medium, size: 12)
            return cell
        }
    }
    
}

//MARK: - MKLocalSearchCompleterDelegate

extension SearchSuggestionsTableViewController: MKLocalSearchCompleterDelegate {
    
    /// - Tag: QueryResults
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completerResults = completer.results
        completerResults.forEach({ completion in
            //make a call to our personal data base for an icon & number of posts nearby
        })
        handleFinishedSearch()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        
    }
}

//MARK: - UISearchResultsUpdating

extension SearchSuggestionsTableViewController: UISearchResultsUpdating {
    
    //This is called each time the text in the search bar is updated
    func updateSearchResults(for searchController: UISearchController) {
        guard let untrimmedSearchText = searchController.searchBar.text else { return }
        searchText = untrimmedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else {
            //Remove all results immediately when the user deletes all the searchText
            searchCompleter.queryFragment = "" //reset searchQuery. important in case the user types in "b", deletes "b", then types in "b" again
            completerResults = []
            wordResults = []
            tableView.reloadData()
            return
        }
        
        didOneSearchAlreadyFinish = false
        startNearbySearch(with: searchText)
        startWordSearch(with: searchText)
    }
}

//MARK: - Search Helpers

extension SearchSuggestionsTableViewController {

    func startNearbySearch(with searchText: String) {
        searchCompleter.queryFragment = searchText //queries new suggestions from apple
    }
    
    func startWordSearch(with searchText: String) {
        Task {
            do {
                let searchWords = searchText.components(separatedBy: .whitespaces)
                guard let lastWord = searchWords.last else { return }
                let wrapperWords = Array(searchWords.prefix(searchWords.count - 1))
                let allResults = try await WordAPI.fetchWords(search_word: lastWord,
                                                              wrapper_words: wrapperWords)
                sortAndTrimNewWordResults(allResults)
                handleFinishedSearch()
            } catch {
//                if (error as! APIError).rawValue == APIError.Throttled.rawValue {
//                    print("throttled. not throwing a custom swift message for now")
//                } else {
                    CustomSwiftMessages.displayError(error)
//                }
            }
        }
    }
    
    private func sortAndTrimNewWordResults(_ allResults: [Word]) {
        wordResults = Array(allResults.sorted(by: { wordOne, wordTwo in
            wordOne.occurrences > wordTwo.occurrences
        }).prefix(5))
    }
    
    private func handleFinishedSearch() {
        if !didOneSearchAlreadyFinish {
            didOneSearchAlreadyFinish = true
            return
        }
        
        guard !searchText.isEmpty else { return } //If the user deleted all the searchText before the searchQuery finished, we don't want to display any results
        
        tableView.reloadData()
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
