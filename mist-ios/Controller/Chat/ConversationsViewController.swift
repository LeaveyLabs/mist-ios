//
//  MessagesViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/04.
//

import UIKit

class ConversationsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var customNavBar = CustomNavBar()
    @IBOutlet weak var noConvosStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        registerNibs()
        setupNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        tableView.bounces = ConversationService.singleton.getCount() > 0 ? true : false
        noConvosStackView.isHidden = ConversationService.singleton.getCount() > 0
    }
    
    //MARK: - Setup
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
    }
    
    private func registerNibs() {
        let conversationNib = UINib(nibName: Constants.SBID.Cell.Conversation, bundle: nil)
        tableView.register(conversationNib, forCellReuseIdentifier: Constants.SBID.Cell.Conversation)
    }
    
    func setupNavBar() {
        navigationController?.isNavigationBarHidden = true
        view.addSubview(customNavBar)
        customNavBar.configure(title: "dms", leftItems: [.title], rightItems: [.profile], delegate: self)
    }
    
}

extension ConversationsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if ConversationService.singleton.getCount() > 0 {
            let chatVC = ChatViewController.create(conversation: ConversationService.singleton.getConversationAt(index: indexPath.row)!)
            navigationController?.pushViewController(chatVC, animated: true)
        }
    }
    
}

extension ConversationsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, ConversationService.singleton.getCount())
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ConversationService.singleton.getCount() == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "NoConversationsCell", for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Conversation) as! ConversationCell
            cell.configureWith(conversation: ConversationService.singleton.getConversationAt(index: indexPath.row)!)
            return cell
        }
    }
    
}

extension ConversationsViewController: CustomNavBarDelegate {
    
    @objc func handleProfileButtonTap() {
        guard
            let myAccountNavigation = storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation) as? UINavigationController,
            let myAccountVC = myAccountNavigation.topViewController as? MyAccountViewController
        else { return }
        myAccountNavigation.modalPresentationStyle = .fullScreen
        myAccountVC.rerenderProfileCallback = { } //no longer needed, since we update the accountButton on moveToSuperview
        self.navigationController?.present(myAccountNavigation, animated: true, completion: nil)
    }

    @objc func handleFilterButtonTap() {
        fatalError("not used")
    }

    @objc func handleMapFeedToggleButtonTap() {
        fatalError("not used")
    }

    @objc func handleSearchButtonTap() {
        fatalError("not used")
    }

    @objc func handleCloseButtonTap() {
        fatalError("not used")
    }

    @objc func handleBackButtonTap() {
        fatalError("not used")
    }
    
}
