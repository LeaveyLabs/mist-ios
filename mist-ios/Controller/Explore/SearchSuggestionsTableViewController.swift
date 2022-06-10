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
    var selectedScope: MapSearchScope = .init(rawValue: 0)!
    var liveResults = [Any]()
    
    //Map Search
    private var searchCompleter: MKLocalSearchCompleter?
    var completerResults: [MKLocalSearchCompletion]?
    
    @IBOutlet weak var resultsLabel: UILabel!
    @IBOutlet weak var resultsLabelView: UIView!
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCells()
        resultsLabelView.isHidden = true
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

//Public interface

extension SearchSuggestionsTableViewController {
    
    func updatePlacemark(_ placemark: CLPlacemark?, boundingRegion: MKCoordinateRegion) {
//        currentPlacemark = placemark //would only be useful for displaying a title label like "results near LA"
        searchCompleter?.region = boundingRegion
    }
    
}

// MARK: - UITableViewDataSource

extension SearchSuggestionsTableViewController {
        
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedScope {
        case .locatedAt:
            return completerResults?.count ?? 0
        case .containing:
            return liveResults.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedScope {
        case .locatedAt:
            let cell = tableView.dequeueReusableCell(withIdentifier: SuggestedCompletionTableViewCell.reuseID, for: indexPath)
            if let suggestion = completerResults?[indexPath.row] {
                // Each suggestion is a MKLocalSearchCompletion with a title, subtitle, and ranges describing what part of the title
                // and subtitle matched the current query string. The ranges can be used to apply helpful highlighting of the text in
                // the completion suggestion that matches the current query fragment.
                cell.textLabel?.attributedText = createHighlightedString(text: suggestion.title, rangeValues: suggestion.titleHighlightRanges)
                cell.detailTextLabel?.attributedText = createHighlightedString(text: suggestion.subtitle, rangeValues: suggestion.subtitleHighlightRanges)
            }
            return cell
        case .containing:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.WordResult, for: indexPath) as! WordResultCell
            cell.configureWordCell(word: liveResults[indexPath.row] as! Word, parent: self)
            return cell
        }
    }
    
    private func createHighlightedString(text: String, rangeValues: [NSValue]) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.backgroundColor: mistSecondaryUIColor() ]
        let highlightedString = NSMutableAttributedString(string: text)
        
        // Each `NSValue` wraps an `NSRange` that can be used as a style attribute's range with `NSAttributedString`.
        let ranges = rangeValues.map { $0.rangeValue }
        ranges.forEach { (range) in
            highlightedString.addAttributes(attributes, range: range)
        }
        
        return highlightedString
    }
}

//MapSearch in particular

extension SearchSuggestionsTableViewController: MKLocalSearchCompleterDelegate {
    
    /// - Tag: QueryResults
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // As the user types, new completion suggestions are continuously returned to this method.
        // Overwrite the existing results, and then refresh the UI with the new results.
        
        if !searchText.isEmpty { //Check that the user didn't delete the search query before it finished
            completerResults = completer.results
            tableView.reloadData()
            resultsLabelView.isHidden = false
            resultsLabel.text = completerResults!.isEmpty ? "No locations found": String(format:"%d locations found", completerResults!.count)
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle any errors returned from MKLocalSearchCompleter.
//        if let error = error as NSError? {
//            print("MKLocalSearchCompleter encountered an error: \(error.localizedDescription). The query fragment is: \"\(completer.queryFragment)\"")
//        }
    }
}

//Both map and text search

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
            liveResults = []
            tableView.reloadData()
            resultsLabelView.isHidden = true
            return
        }
        
        resultsLabelView.isHidden = false
        resultsLabel.text = "Searching..."
        switch selectedScope {
        case .locatedAt:
            // Ask `MKLocalSearchCompleter` for new completion suggestions based on the change in the text entered in `UISearchBar`.
            searchCompleter?.queryFragment = "" //when the user toggles the selected scope, the query fragment has not actually changed, so we must incorrectly and then recorrectly set it to force a new search
            searchCompleter?.queryFragment = searchText
        case .containing:
            Task {
                do {
                    liveResults = try await WordAPI.fetchWords(text: searchText)
                    if !searchText.isEmpty { //Check that the user didn't delete the search query before it finished
                        tableView.reloadData()
                        resultsLabelView.isHidden = false
                        resultsLabel.text = liveResults.isEmpty ? "No mists found": String(format:"%d mists found", liveResults.count)
                    }
                } catch {
                    CustomSwiftMessages.showError(errorDescription: error.localizedDescription)
                }
            }
        }
    }
    
}

private class SuggestedCompletionTableViewCell: UITableViewCell {
    
    static let reuseID = "SuggestedCompletionTableViewCellReuseID"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
