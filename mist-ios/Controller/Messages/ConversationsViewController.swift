//
//  MessagesViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/04.
//

import UIKit

struct Conversation {
    var otherUser: User
    var firstMessage: Message
}

class ConversationsViewController: UIViewController {
    
    @IBOutlet weak var conversationsTableView: UITableView!
    @IBOutlet weak var mistTitle: UIView! //no longer in use
    
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
        navigationItem.rightBarButtonItem = UIBarButtonItem.imageButton(self,
                                                                      action: #selector(presentMyAccount),
                                                                      imageName: "adam")
    }
    
    @objc func presentMyAccount() {
        let myAccountNavigation = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation)
        myAccountNavigation.modalPresentationStyle = .fullScreen
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
        print( max(1, conversations.count))
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
