//
//  ProfileViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class ProfileViewController: UIViewController {
    
    var username: String!
    var profile: Profile?

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
    
    //TODO: need to load if this user is friends with current user
    func loadProfile() {
        Task {
            do {
                let profiles = try await ProfileAPI.fetchProfiles(text: username)
                profile = profiles[0]
            } catch {
                print(error)
            }
        }
    }

}
