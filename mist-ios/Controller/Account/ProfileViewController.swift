//
//  ProfileViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class ProfileViewController: UIViewController {
    
    var username: String!
    var user: ReadOnlyUser?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: User Interaction
    
    @IBAction func cancelButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func moreButtonDidPressed(_ sender: UIButton) {
        
    }
    
    //MARK: -Db Calls
    
    func loadProfile() {
        Task {
            do {
                let dbUser = try await UserAPI.fetchUsersByUsername(username: username)[0]
            } catch {
                print(error)
            }
        }
    }

}
