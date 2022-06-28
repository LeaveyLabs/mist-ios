//
//  MessagesViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/04.
//

import UIKit

class ConversationsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var accountButton: UIButton!
    @IBOutlet weak var customNavigationBar: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        registerNibs()
        setupMyAccountButton()
        navigationController?.isNavigationBarHidden = true
        customNavigationBar.applyLightBottomOnlyShadow()
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
    
    private func setupMyAccountButton() {
        accountButton.addTarget(self, action: #selector(presentMyAccount), for: .touchUpInside)
        accountButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
    }
    
    @objc func presentMyAccount() {
        let myAccountNavigation = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation) as! UINavigationController
        myAccountNavigation.modalPresentationStyle = .fullScreen
        let myAccountVC = myAccountNavigation.topViewController as! MyAccountViewController
        myAccountVC.rerenderProfileCallback = {
            self.accountButton.setImage(UserService.singleton.getProfilePic(), for: .normal)
        }
        self.navigationController?.present(myAccountNavigation, animated: true, completion: nil)
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if ConversationService.singleton.getCount() == 0 {
            return tableView.frame.height / 4
        } else {
            tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
            return 0 //for some reason, tableViews cant have a default header shorter than like 20 pixels. so if you return 10, it gets minned to 20
        }
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
