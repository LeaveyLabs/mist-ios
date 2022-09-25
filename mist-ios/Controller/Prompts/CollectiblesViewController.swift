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
    var collectibles: [Int] = CollectibleManager.shared.earned_collectibles 
        
    class func create() -> CollectiblesViewController {
        let vc = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Collectibles) as! CollectiblesViewController
        return vc
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
        tableView.estimatedRowHeight = 80
        tableView.register(CollectibleCell.self, forCellReuseIdentifier: String(describing: CollectibleCell.self))
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        collectibles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String.init(describing: CollectibleCell.self), for: indexPath) as! CollectibleCell
        cell.configure(collectibleType: collectibles[indexPath.row], delegate: self)
        return cell
    }
    
    //MARK: - User interactiopn
    
    @objc func didPressBack() {
        navigationController?.popViewController(animated: true)
    }
    
}

extension CollectiblesViewController: CollectibleViewDelegate {
    
    func collectibleDidTapped(type: Int) {
        guard let collectiblePost = PostService.singleton.getSubmissions().first(where: { $0.collectible_type == type }) else { return }
        let postVC = PostViewController.createPostVC(with: collectiblePost, shouldStartWithRaisedKeyboard: false, completionHandler: nil)
        navigationController!.pushViewController(postVC, animated: true)
    }
    
}
