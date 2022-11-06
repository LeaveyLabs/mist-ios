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
        
        (tabBarController?.tabBar as? SpecialTabBar)?.middleButton.isHidden = true
        (tabBarController as? SpecialTabBarController)?.refreshBadgeCount()
        
        customNavBar.accountBadgeHub.setCount(DeviceService.shared.unreadMentionsCount())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (tabBarController?.tabBar as? SpecialTabBar)?.middleButton.isHidden = false
    }
    
    //MARK: - Setup
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.tableHeaderView = UIView(frame: .init(x: 0, y: 0, width: tableView.frame.width, height: 5)) //balance out the cell distance visually
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl!.addTarget(self, action: #selector(reloadConvos), for: .valueChanged)
    }
    
    private func registerNibs() {
        let conversationNib = UINib(nibName: Constants.SBID.Cell.Conversation, bundle: nil)
        tableView.register(conversationNib, forCellReuseIdentifier: Constants.SBID.Cell.Conversation)
    }
    
    func setupNavBar() {
        navigationController?.isNavigationBarHidden = true
        view.addSubview(customNavBar)
        customNavBar.configure(title: "dms", leftItems: [.title], rightItems: [.profile])
        customNavBar.accountButton.addTarget(self, action: #selector(handleProfileButtonTap), for: .touchUpInside)
    }
    
    //MARK: - UserInteraction
    
    @objc func reloadConvos() {
        Task {
            do {
                try await ConversationService.singleton.loadInitialMessageThreads()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                    (self.tabBarController as? SpecialTabBarController)?.refreshBadgeCount()
                }
            } catch {
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    @IBAction func keepMistingButtonDidPressed() {
        let vc = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.HowMistWorks) as! HowMistWorksViewController
        present(vc, animated: true)
    }
    
}

extension ConversationsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard !(tableView.refreshControl?.isRefreshing ?? false) else { return }
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
