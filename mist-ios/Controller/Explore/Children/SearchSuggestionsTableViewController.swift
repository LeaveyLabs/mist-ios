//
//  ResultsTableViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit
import MapKit

struct SearchResults {
    var wordResults: [Word]
    var completerResults: [MKLocalSearchCompletion]
}

class SearchSuggestionsTableViewController: UITableViewController {
    
    //MARK: - Properties
    
    //Search
    private var searchText = ""
    
    var searchType: MapSearchResultType = .containing
    var searchResults = SearchResults(wordResults: [], completerResults: [])
    var searchResultsCache = [String: SearchResults]()
    var searchResultsTasks = [String: Task<Void, Never>]()
    
    //Map Search
    private var searchCompleter = MKLocalSearchCompleter()
    
    var isFragmentSearchEnabled = false
    
    var activityIndicator = UIActivityIndicatorView(style: .medium)
    
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCells()
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        activityIndicator.isHidden = true
        activityIndicator.frame = .init(x: tableView.frame.width - 30, y: -10, width: 20, height: 20)
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
    
    func startProvidingCompletions(for region: MKCoordinateRegion, searchType: MapSearchResultType) {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.pointOfInterest, .address]
        searchCompleter.region = region
        self.searchType = searchType
    }
}

// MARK: - UITableViewDataSource

extension SearchSuggestionsTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !searchText.isEmpty else { return "" }
        return searchType.sectionName
    }
    
    //Fix font
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont(name: Constants.Font.Medium, size: 15)
        header.textLabel?.text = header.textLabel?.text?.lowercased()
    }
            
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchText.isEmpty { return 0 }
        switch searchType {
        case .containing:
            return max(searchResults.wordResults.count, 1) //return 1 "no results" cell
        case .nearby:
            return max(searchResults.completerResults.count + (isFragmentSearchEnabled ? 1 : 0), 1)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch searchType {
        case .containing:
            var wrapperWords: [String] = []
            let searchWords = searchText.condensed.components(separatedBy: .whitespaces)
            if searchWords.count > 0 {
                wrapperWords = Array(searchWords.prefix(searchWords.count - 1))
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.SearchResult, for: indexPath) as! SearchResultCell
            if !searchResults.wordResults.isEmpty {
                cell.configureWordCell(word: searchResults.wordResults[indexPath.row], wrapperWords: wrapperWords)
            } else {
                cell.configureNoWordResultsCell()
            }
            cell.textLabel?.font = UIFont(name: Constants.Font.Medium, size: 16)
            cell.subtitleLabel?.font = UIFont(name: Constants.Font.Medium, size: 12)
            return cell
        case .nearby:
            let cell = tableView.dequeueReusableCell(withIdentifier: SuggestedCompletionTableViewCell.reuseID, for: indexPath)
            cell.imageView?.image = UIImage(systemName: "mappin.circle")
            if !searchResults.completerResults.isEmpty {
                if isFragmentSearchEnabled && indexPath.row == 0 {
                    cell.textLabel?.text = searchText // + "\""
                    cell.detailTextLabel?.text = "nearby search"
                    cell.accessoryType = .disclosureIndicator
                    cell.isUserInteractionEnabled = true
                } else {
                    let suggestion = searchResults.completerResults[isFragmentSearchEnabled ? indexPath.row-1 : indexPath.row]
                    cell.textLabel?.text = suggestion.title.lowercased()
                    cell.detailTextLabel?.text = suggestion.subtitle.lowercased()
                    cell.accessoryType = .disclosureIndicator
                    cell.isUserInteractionEnabled = true
                }
            } else {
                cell.textLabel?.text = "no results"
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
        searchResultsCache[completer.queryFragment] = SearchResults(wordResults: [], completerResults: completer.results)
        handleFinishedSearch(forQuery: completer.queryFragment)
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
        
        //Check if search was cancelled
        guard !searchText.isEmpty else {
            //Remove all results immediately when the user deletes all the searchText
            searchCompleter.queryFragment = "" //reset searchQuery. important in case the user types in "b", deletes "b", then types in "b" again
            searchResults = .init(wordResults: [], completerResults: [])
            activityIndicator.isHidden = true
            tableView.reloadData()
            return
        }
        
        //Check if the search was already cached
        if let cachedSearch = searchResultsCache[searchText] {
            DispatchQueue.main.async { [weak self] in
                self?.searchResults = cachedSearch
                self?.tableView.reloadData()
                self?.tableView.flashScrollIndicators()
                self?.activityIndicator.isHidden = true
            }
            return
        }
        
        //Check if search is in progress
        if let inProgressTask = searchResultsTasks[searchText],
            !inProgressTask.isCancelled {
            //the autocompletion is currently loading: wait for it to finish
            activityIndicator.isHidden = false
            return
        }
        
        switch searchType {
        case .containing:
            startWordSearch(with: searchText)
        case .nearby:
            startNearbySearch(with: searchText)
        }
        activityIndicator.isHidden = false
    }
}

//MARK: - Search Helpers

extension SearchSuggestionsTableViewController {

    func startNearbySearch(with searchText: String) {
        searchCompleter.queryFragment = searchText //queries new suggestions from apple
    }
    
    func startWordSearch(with searchText: String) {
        searchResultsTasks[searchText] = Task {
            do {
                let searchWords = searchText.components(separatedBy: .whitespaces)
                guard let lastWord = searchWords.last else { return }
                let wrapperWords = Array(searchWords.prefix(searchWords.count - 1))
                let loadedWords = try await WordAPI.fetchWords(search_word: lastWord,
                                                              wrapper_words: wrapperWords)
                let trimmedResults = sortAndTrimNewWordResults(loadedWords)
                
                searchResultsCache[searchText] = SearchResults(wordResults: trimmedResults, completerResults: [])
                handleFinishedSearch(forQuery: searchText)
                
            } catch {
                searchResultsTasks[searchText]?.cancel()
                CustomSwiftMessages.displayError(error)
                DispatchQueue.main.async { [weak self] in
                    self?.searchResults = .init(wordResults: [], completerResults: [])
                    self?.tableView.reloadData()
                    self?.activityIndicator.isHidden = true
                    self?.tableView.flashScrollIndicators()
                }
            }
        }
    }
    
    private func sortAndTrimNewWordResults(_ allResults: [Word]) -> [Word] {
        return Array(allResults.sorted(by: { wordOne, wordTwo in
            wordOne.occurrences > wordTwo.occurrences
        }).prefix(5))
    }
    
    @MainActor
    private func handleFinishedSearch(forQuery query: String) {
        guard
            query == self.searchText,
            let cachedResults = searchResultsCache[query]
        else { return }
        searchResults = cachedResults
        tableView.reloadData()
        tableView.flashScrollIndicators()
        activityIndicator.isHidden = true
    }
    
}

//MARK: - Suggestion TableViewCell

class SuggestedCompletionTableViewCell: UITableViewCell {
    
    static let reuseID = "SuggestedCompletionTableViewCellReuseID"
    let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        textLabel?.font = UIFont(name: Constants.Font.Roman, size: 15) //originally 17
        detailTextLabel?.font = UIFont(name: Constants.Font.Book, size: 11) //originally 12
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        loadingIndicator.isHidden = true
        imageView?.isHidden = false
    }
    
    func startLoadingAnimation() {
        loadingIndicator.color = Constants.Color.mistBlack
        loadingIndicator.frame = imageView!.frame
        loadingIndicator.startAnimating()
        contentView.addSubview(loadingIndicator)
        contentView.bringSubviewToFront(loadingIndicator)
        
        imageView?.isHidden = true
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
    }
}
