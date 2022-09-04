//
//  EnterKeywordsViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import Foundation

class EnterKeywordsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
    typealias EnterKeywordsCallback = (Int) -> Void
    
    @IBOutlet weak var customNavBar: CustomNavBar!
    @IBOutlet weak var tableView: UITableView!
    var localTags: [String] = UserService.singleton.getKeywords()
    
    var callback: EnterKeywordsCallback!
    
    class func create(callback: @escaping EnterKeywordsCallback) -> EnterKeywordsViewController {
        let keywordsVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterKeywords) as! EnterKeywordsViewController
        keywordsVC.callback = callback
        return keywordsVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.bounces = true
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        navigationController?.fullscreenInteractivePopGestureRecognizer(delegate: self)

        customNavBar.configure(title: "keywords", leftItems: [.back, .title], rightItems: [], delegate: self)
        tableView.register(TagsViewCell.self, forCellReuseIdentifier: String(describing: TagsViewCell.self))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        didPressSaveButton() //could move this to a save button instead... oh well
        callback(localTags.count)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TagsViewCell.self), for: indexPath) as! TagsViewCell
        cell.configure(existingKeywords: localTags, delegate: self)
        
        cell.tagsField.onDidChangeHeightTo = { [weak tableView] _, _ in
            tableView?.beginUpdates()
            tableView?.endUpdates()
        }

        return cell
    }
    
}

extension EnterKeywordsViewController: TagsViewDelegate {
    
    func didUpdateTags(tags: [String]) {
        localTags = tags
//        didPressSaveButton()
//        customNavBar.saveButton.isEnabled = localTags != UserService.singleton.getKeywords()
    }
    
    func didPressSaveButton() {
        Task {
            do {
                try await UserService.singleton.updateKeywords(to: localTags)
//                customNavBar.saveButton.isEnabled = false
            } catch {
                CustomSwiftMessages.displayError(error)
            }
        }
    }
}

extension EnterKeywordsViewController: CustomNavBarDelegate {
    
    @objc func handleProfileButtonTap(sender: UIButton) {
        
    }

    @objc func handleFilterButtonTap(sender: UIButton) {
        fatalError("not used")
    }

    @objc func handleMapFeedToggleButtonTap(sender: UIButton) {
        fatalError("not used")
    }

    @objc func handleSearchButtonTap(sender: UIButton) {
        fatalError("not used")
    }

    @objc func handleCloseButtonTap(sender: UIButton) {
        dismiss(animated: true)
    }

    @objc func handleBackButtonTap(sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
}
