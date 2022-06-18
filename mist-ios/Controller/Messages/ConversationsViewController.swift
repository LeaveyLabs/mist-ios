//
//  MessagesViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/04.
//

import UIKit

struct Conversation {
    var otherUser: ReadOnlyUser
    var firstMessage: Message
}

class ConversationsViewController: UIViewController {
    
    @IBOutlet weak var conversationsTableView: UITableView!
    @IBOutlet weak var mistTitle: UIView! //no longer in use
    var accountButton: UIButton!
    
    var conversations: [Conversation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupMyAccountButton()
    }
    
    //MARK: - Setup
    
    private func setupTableView() {
        conversationsTableView.delegate = self
        conversationsTableView.dataSource = self
        conversationsTableView.estimatedRowHeight = 100;
        conversationsTableView.rowHeight = UITableView.automaticDimension
    }
    
    private func setupMyAccountButton() {
        accountButton = UIButton(frame: .init(x: 0, y: 0, width: 30, height: 30))
        accountButton.setImage(UserService.singleton.getProfilePic(), for: .normal)
        accountButton.addTarget(self, action: #selector(presentMyAccount), for: .touchUpInside)
        accountButton.contentMode = .scaleAspectFill
        accountButton.becomeRound() //if creating programmaticallly, must set a width and height of the view before calling becomeRound()

        let accountBarItem = UIBarButtonItem(customView: accountButton)
        accountBarItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        accountBarItem.customView?.heightAnchor.constraint(equalToConstant: accountButton.frame.height).isActive = true
        accountBarItem.customView?.widthAnchor.constraint(equalToConstant: accountButton.frame.width).isActive = true
        
        navigationItem.rightBarButtonItem = accountBarItem
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
