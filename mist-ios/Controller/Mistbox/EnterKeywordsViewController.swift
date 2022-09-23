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
    var saveButton = UIButton()
    var localTags: [String] = MistboxManager.shared.getCurrentKeywords()
        
    class func create() -> EnterKeywordsViewController {
        let keywordsVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterKeywords) as! EnterKeywordsViewController
        return keywordsVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupFooterLabel()
        setupCustomNavBar()
    }
    
    func setupTableView() {
        tableView.bounces = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
        //keyboard will always be raised, so this is the estimated keyboard height
        tableView.contentInset.bottom = 300 + (window?.safeAreaInsets.bottom ?? 0)
        tableView.register(TagsViewCell.self, forCellReuseIdentifier: String(describing: TagsViewCell.self))
    }
    
    func setupCustomNavBar() {
        if MistboxManager.shared.hasUserActivatedMistbox { //we dont want them slide to pop back on the very first flow
            customNavBar.configure(title: "keywords", leftItems: [.back, .title], rightItems: [])
            customNavBar.backButton.addTarget(self, action: #selector(didPressBack), for: .touchUpInside)
            navigationController?.fullscreenInteractivePopGestureRecognizer(delegate: self)
        } else {
            customNavBar.configure(title: "keywords", leftItems: [.title], rightItems: [])
//            customNavBar.backButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)), for: .normal)
        }
        
        saveButton.clipsToBounds = true
        saveButton.setBackgroundImage(UIImage.imageFromColor(color: Constants.Color.mistLilac), for: .normal)
        saveButton.setTitle("save", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.roundCornersViaCornerRadius(radius: 5)
        saveButton.setTitleColor(.lightGray, for: .disabled)
        saveButton.titleLabel?.font = UIFont(name: Constants.Font.Heavy, size: 18)
        saveButton.setBackgroundImage(UIImage.imageFromColor(color: .systemGray5.withAlphaComponent(0.5)), for: .disabled)
        saveButton.isEnabled = false
        saveButton.adjustsImageWhenDisabled = true
        saveButton.adjustsImageWhenHighlighted = true
        saveButton.backgroundColor = .clear
        saveButton.addTarget(self, action: #selector(didPressSaveButton), for: .touchUpInside)
        customNavBar.stackView.addArrangedSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            saveButton.heightAnchor.constraint(equalToConstant: 35),
            saveButton.widthAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    func setupFooterLabel() {
        let footerLabel: UILabel
        
        if MistboxManager.shared.hasUserActivatedMistbox {
            footerLabel = UILabel(frame: .init(x: 0, y: 0, width: view.bounds.width, height: 30))
            footerLabel.text = "updates won't affect your current mistbox"
        } else {
            footerLabel = UILabel(frame: .init(x: 0, y: 0, width: view.bounds.width, height: 60))
            footerLabel.numberOfLines = 4
            footerLabel.text = "enter up to 10 keywords that describe you &\nfind out when someone posts a mist with them"
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
        navigationController?.popViewController(animated: true)
    }
    
}

extension EnterKeywordsViewController: TagsViewDelegate {
    
    func didUpdateTags(tags: [String]) {
        localTags = tags
        saveButton.isEnabled = localTags != MistboxManager.shared.getCurrentKeywords()
    }
    
    @objc func didPressSaveButton() {
        let hasActivatedBeforeSave = MistboxManager.shared.hasUserActivatedMistbox
        saveButton.loadingIndicator(true)
        saveButton.setTitle("", for: .disabled)
        
        print("DID PRESS SAVE BUTTON")
        
        Task {
            do {
                try await MistboxManager.shared.updateKeywords(to: localTags)
                DispatchQueue.main.async {
                    self.saveButton.loadingIndicator(false)
                    self.saveButton.setTitle("saved", for: .disabled)
                    self.saveButton.isEnabled = self.localTags != MistboxManager.shared.getCurrentKeywords()
                    if !hasActivatedBeforeSave {
                        self.dismiss(animated: true)
                    }
                }
            } catch {
                CustomSwiftMessages.displayError(error)
                DispatchQueue.main.async {
                    self.saveButton.loadingIndicator(false)
                    self.saveButton.setTitle("save", for: .disabled)
                }
            }
        }
    }
    
}
