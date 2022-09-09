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
    var localTags: [String] = MistboxManager.shared.getCurrentKeywords()
        
    class func create() -> EnterKeywordsViewController {
        let keywordsVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterKeywords) as! EnterKeywordsViewController
        return keywordsVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.bounces = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
        //keyboard will always be raised, so this is the estimated keyboard height
        tableView.contentInset.bottom = 300 + (window?.safeAreaInsets.bottom ?? 0)
        
        if MistboxManager.shared.hasUserActivatedMistbox { //we dont want them slide to pop back on the very first flow
            navigationController?.fullscreenInteractivePopGestureRecognizer(delegate: self)
        }

        customNavBar.configure(title: "keywords", leftItems: [.back, .title], rightItems: [])
        customNavBar.backButton.addTarget(self, action: #selector(didPressBack), for: .touchUpInside)
        tableView.register(TagsViewCell.self, forCellReuseIdentifier: String(describing: TagsViewCell.self))
        setupFooterLabel()
    }
    
    func setupFooterLabel() {
        let footerLabel = UILabel(frame: .init(x: 0, y: 0, width: view.bounds.width, height: 15))
        
        if MistboxManager.shared.hasUserActivatedMistbox {
            footerLabel.text = "updates won't affect your current mistbox"
        } else {
            footerLabel.text = "enter up to 10 keywords"
        }
        footerLabel.font = UIFont(name: Constants.Font.Roman, size: 13)
        footerLabel.textColor = .lightGray
        footerLabel.minimumScaleFactor = 0.5
        footerLabel.textAlignment = .center
        tableView.tableFooterView = footerLabel
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
        didPressSaveButton()
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
    
    //MARK: - User interactiopn
    
    @objc func didPressBack() {
        if MistboxManager.shared.hasUserActivatedMistbox {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
}

extension EnterKeywordsViewController: TagsViewDelegate {
    
    func didUpdateTags(tags: [String]) {
        localTags = tags
    }
    
    func didPressSaveButton() {
        MistboxManager.shared.updateKeywords(to: localTags)
    }
}
