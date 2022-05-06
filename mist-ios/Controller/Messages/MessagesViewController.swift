//
//  MessagesViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/04.
//

import UIKit

class MessagesViewController: UIViewController {
    
    @IBOutlet weak var messagesTableView: UITableView!
    
    @IBOutlet weak var mistTitle: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = mistTitle

        // Do any additional setup after loading the view.
    }
    
    @IBAction func myProfileButtonDidTapped(_ sender: UIBarButtonItem) {
        let myAccountNavigation = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation)
        myAccountNavigation.modalPresentationStyle = .fullScreen
        self.navigationController?.present(myAccountNavigation, animated: true, completion: nil)
    }
    
}

extension MessagesViewController: UITableViewDelegate {
    
}

//extension MessagesViewController: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        0
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//    }
//    
//    
//}
