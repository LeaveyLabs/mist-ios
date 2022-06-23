//
//  MessagesViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/04.
//

import UIKit

struct Conversation {
    var sangdaebang: FrontendReadOnlyUser
    var messageThread: MessageThread
}

class ConversationsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var accountButton: UIButton!
    @IBOutlet weak var customNavigationBar: UIView!
    
    var conversations: [Conversation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
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
        if conversations.count == 0 { return }
        else {
            //create simpleChatConversation
            //set simpleChatConversation.user to conversations[indexPath].user
            //push to simpleChatConversation
        }
    }
    
}

extension ConversationsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return conversations.count == 0 ? tableView.frame.height / 4 : 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, conversations.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (conversations.count == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoConversationsCell", for: indexPath)
            return cell
        }
        else {
            var conversation = conversations[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.Conversation)! //as
            //cell.configureConversationCell(conversation: conversations[indexPath.row], parent: self)

            return cell
        }
    }
    
}
