//
//  ProfileViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import UIKit

class ProfileViewController: UIViewController {
    
    //MARK: - Properties
    
    //UI
    @IBOutlet weak var profilePicUIImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var friendStatusView: UIView!
    
    //Data
    var user: FrontendReadOnlyUser!
    
    //MARK: - Constructors
    
    class func createProfileVC(with user: FrontendReadOnlyUser) -> ProfileViewController {
        let profileVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Profile) as! ProfileViewController
        profileVC.user = user
        return profileVC
    }
    
    //MARK: - Lifecycl;e

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
    
//    func loadProfile() {
//        Task {
//            do {
//                let readOnlyUserResults = try await UserAPI.fetchUsersByUsername(username: username)
//                guard readOnlyUserResults.count == 1 else { throw APIError.NotFound }
//                user = FrontendReadOnlyUser(readOnlyUser: readOnlyUserResults[0],
//                                            profilePic: profilePic)
//            } catch {
//                CustomSwiftMessages.displayError(error)
//            }
//        }
//    }

}
