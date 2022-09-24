//
//  CollectiblesViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/24/22.
//

import Foundation

class CollectiblesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    typealias EnterKeywordsCallback = (Int) -> Void
    
    @IBOutlet weak var customNavBar: CustomNavBar!
    @IBOutlet weak var tableView: UITableView!
    var collectibles: [String] = []//UserService.singleton.getBad
        
    class func create() -> CollectiblesViewController {
        let keywordsVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Collectibles) as! CollectiblesViewController
        return keywordsVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupCustomNavBar()
    }
    
    func setupTableView() {
        tableView.bounces = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        
        tableView.register(TagsViewCell.self, forCellReuseIdentifier: String(describing: TagsViewCell.self))
    }
    
    func setupCustomNavBar() {
        customNavBar.configure(title: "collectibles", leftItems: [.back, .title], rightItems: [])
        customNavBar.backButton.addTarget(self, action: #selector(didPressBack), for: .touchUpInside)
        navigationController?.fullscreenInteractivePopGestureRecognizer(delegate: self)
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
        collectibles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TagsViewCell.self), for: indexPath) as! TagsViewCell
//        cell.configure(existingKeywords: localTags, delegate: self)
//        
//        cell.tagsField.onDidChangeHeightTo = { [weak tableView] _, _ in
//            tableView?.beginUpdates()
//            tableView?.endUpdates()
//        }

        return cell
    }
    
    //MARK: - User interactiopn
    
    @objc func didPressBack() {
        navigationController?.popViewController(animated: true)
    }
    
}
