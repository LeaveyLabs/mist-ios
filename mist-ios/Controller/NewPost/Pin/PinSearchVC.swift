//
//  NewPostViewController+Search.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/2/22.
//

import Foundation
import Foundation
import CoreLocation
import MapKit


protocol PinSearchChildDelegate {
    func searchResultsUpdated(newResults: [MKMapItem])
    func shouldGoUp()
    func shouldGoDown()
}

class PinSearchViewController: UIViewController {
    
    //Search
    private var searchString = ""
    
    //Map Search
    private var searchCompleter = MKLocalSearchCompleter()
    var completerResults = [MKLocalSearchCompletion]()
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var notchView: UIView!
    @IBOutlet weak var notchHandleView: UIView!
    
    var pinSearchChildDelegate: PinSearchChildDelegate!
    
    //MARK: - Initialization
    
    class func create(delegate: PinSearchChildDelegate) -> PinSearchViewController {
        let vc = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.PinSearch) as! PinSearchViewController
        vc.pinSearchChildDelegate = delegate
        return vc
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        setupTableView()
        setupNotchView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.contentInset.top -= self.view.safeAreaInsets.top //needed bc auto content inset adjustment behavior isn't reflecing safeareainsets for some reason
        tableView.contentInset.bottom = 280 //estimate of keyboard height
        tableView.verticalScrollIndicatorInsets.bottom = 250
        tableView.verticalScrollIndicatorInsets.top -= self.view.safeAreaInsets.top
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.subviews.forEach { subview in
            subview.applyMediumShadow()
        }
        tableView.clipsToBounds = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.register(SuggestedCompletionTableViewCell.self, forCellReuseIdentifier: SuggestedCompletionTableViewCell.reuseID)
        let nib = UINib(nibName: Constants.SBID.Cell.SearchResult, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: Constants.SBID.Cell.SearchResult)
    }
    
    func setupNotchView() {
        notchView.layer.cornerCurve = .continuous
        notchView.layer.cornerRadius = 20
        notchView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Top right corner, Top left corner respectively
        notchView.applyMediumTopOnlyShadow()
        notchHandleView.layer.cornerCurve = .continuous
        notchHandleView.layer.cornerRadius = 2
    }

    func setupSearchBar() {
        searchBar.setValue("cancel", forKey: "cancelButtonText")
        searchBar.delegate = self // Monitor when the search button is tapped.
        searchBar.tintColor = cornerButtonGrey
        searchBar.searchTextField.tintColor = Constants.Color.mistLilac
        searchBar.autocapitalizationType = .none
        searchBar.searchTextField.font = UIFont(name: Constants.Font.Roman, size: 18)
    }
    
    //MARK: - PublicInterface
    
    func startProvidingCompletions(around coordinate: CLLocationCoordinate2D?) {
        let coordinate = coordinate ?? Constants.Coordinates.USC
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.pointOfInterest, .address]
        searchCompleter.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 100, longitudinalMeters: 100)
    }

}

    // MARK: - UISearchBarDelegate

extension PinSearchViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        pinSearchChildDelegate.shouldGoUp()
        return true
    }
    
    //as if they clicked on the first table row
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard !completerResults.isEmpty else { return }
        tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0)) //cals the tableviewdelegate function just down below, as if they searched for that word
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchString = ""
        completerResults = []
        tableView.reloadData()
        searchBar.searchTextField.resignFirstResponder()
        pinSearchChildDelegate.shouldGoDown()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let untrimmedSearchText = searchBar.text else { return }
        searchString = untrimmedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchString.isEmpty else {
            //Remove all results immediately when the user deletes all the searchText
            searchCompleter.queryFragment = "" //reset searchQuery. important in case the user types in "b", deletes "b", then types in "b" again
            completerResults = []
            tableView.reloadData()
            return
        }
        
        startNearbySearch(with: searchString)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

}

// MARK: - UITableViewDelegate

extension PinSearchViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        pinSearchChildDelegate.shouldGoDown()
        if indexPath.row == 0 {
            let query = completerResults[indexPath.row].title
            search(for: query)
        } else {
            let suggestion = completerResults[indexPath.row-1]
            search(for: suggestion) //first gets places from Apple, then calls reloadPosts(0
        }
        
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard
            let header:UITableViewHeaderFooterView = view as? UITableViewHeaderFooterView,
            let textLabel = header.textLabel
        else { return }
        //textLabel.font.pointSize is 13, seems kinda small
        textLabel.font = UIFont(name: Constants.Font.Roman, size: 12)
        textLabel.text = textLabel.text?.lowercased()//.capitalizeFirstLetter()
    }

}

extension PinSearchViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !searchString.isEmpty else { return "" }
        return "nearby locations"
    }
            
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchString.isEmpty { return 0 }
        return max(completerResults.count + 1, 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SuggestedCompletionTableViewCell.reuseID, for: indexPath)
        cell.imageView?.image = UIImage(systemName: "mappin.circle")
        if !completerResults.isEmpty {
            cell.isUserInteractionEnabled = true
            if indexPath.row == 0 {
                cell.textLabel?.text = searchString // + "\""
                cell.detailTextLabel?.text = "nearby search"
                cell.accessoryType = .disclosureIndicator
                cell.isUserInteractionEnabled = true
            } else {
                let suggestion = completerResults[indexPath.row-1]
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

//MARK: - Text search

extension PinSearchViewController: MKLocalSearchCompleterDelegate {
    
    func startNearbySearch(with searchText: String) {
        print("STARTING NEARBY SEARCHC")
        searchCompleter.queryFragment = searchText //queries new suggestions from apple
    }
    
    // Get the results from startNearbySearch()
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completerResults = completer.results
        handleFinishedSearch()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        
    }
    
    func handleFinishedSearch() {
        guard !searchString.isEmpty else { return } //If the user deleted all the searchText before the searchQuery finished, we don't want to display any results
        tableView.reloadData()
    }
}

// MARK: - Map Search after text search

extension PinSearchViewController {

    /// - Parameter suggestedCompletion: A search completion provided by `MKLocalSearchCompleter` when tapping on a search completion table row
    private func search(for suggestedCompletion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: suggestedCompletion)
        search(using: searchRequest)
    }

    /// - Parameter queryString: A search string from the text the user entered into `UISearchBar`
    //Not in use right now. We only let the user search via suggestions. If we let the user search for locations by typing in "star" and pressing search button, then we would need to uncomment this
    private func search(for queryString: String?) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = queryString
        search(using: searchRequest)
    }

    /// - Tag: SearchRequest
    private func search(using searchRequest: MKLocalSearch.Request) {
        searchRequest.region = searchCompleter.region
        searchRequest.resultTypes = [.address, .pointOfInterest]
        let localSearch = MKLocalSearch(request: searchRequest)
        Task {
            do {
                let response = try await localSearch.start()
                guard !response.mapItems.isEmpty else {
                    CustomSwiftMessages.showInfoCard("result not found", "please try searching again", emoji: "🙃")
                    return
                }
                handleFoundSearchLocation(mapItems: response.mapItems)
            } catch {
                if let error = error as? MKError {
                    CustomSwiftMessages.displayError(error)
                    return
                }
            }
        }
    }
    
    func handleFoundSearchLocation(mapItems: [MKMapItem]) {
        searchBar.resignFirstResponder()
        resetSearch()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.pinSearchChildDelegate.searchResultsUpdated(newResults: mapItems)
        }
    }
    
    func resetSearch() {
        searchBar.text = ""
        searchString = ""
        tableView.reloadData()
        searchBar.setShowsCancelButton(false, animated: true)
    }

}
