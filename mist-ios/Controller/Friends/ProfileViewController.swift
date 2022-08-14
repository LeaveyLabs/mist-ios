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
    var user: FrontendReadOnlyUser?
    var userIdForLoading: Int?
    var userPhoneNumberForLoading: String?
    var userHandleForLoading: String?

    enum ProfileStatus: String {
        case loaded, loading, nonexisting, notclaimed
    }
    var hasViewLoaded: Bool = false //flag to not renderUser before vc is loaded
    var status: ProfileStatus! {
        didSet {
            guard hasViewLoaded else { return }
            renderUser()
        }
    }
    
    //MARK: - Constructors
    
    class func create(for user: FrontendReadOnlyUser) -> ProfileViewController {
        let profileVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Profile) as! ProfileViewController
        profileVC.user = user
        profileVC.status = .loaded
        return profileVC
    }
    
    class func createAndLoadData(userId: Int?, userNumber: String?, handle: String) -> ProfileViewController {
        let profileVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Profile) as! ProfileViewController
        profileVC.userIdForLoading = userId
        profileVC.userPhoneNumberForLoading = userNumber
        profileVC.userHandleForLoading = handle
        profileVC.status = .loading
        return profileVC
    }
    
    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        hasViewLoaded = true
        loadUser()
        renderUser()
    }
    
    //MARK: - Helpers
    
    func renderUser() {
        switch status {
        case .loaded:
            guard let user = user else { return }
            profilePicUIImageView.becomeProfilePicImageView(with: user.profilePic)
            nameLabel.text = user.full_name
            usernameLabel.text = "@" + user.username
        case .loading:
            profilePicUIImageView.image = Constants.defaultProfilePic
            nameLabel.text = "Loading..."
            usernameLabel.text = ""
        case .nonexisting:
            guard let handle = userHandleForLoading else { return }
            profilePicUIImageView.image = Constants.defaultProfilePic
            nameLabel.text = "@" + handle
            usernameLabel.text = "This user does not exist"
        case .notclaimed:
            guard let handle = userHandleForLoading else { return }
            profilePicUIImageView.image = Constants.defaultProfilePic
            nameLabel.text = "@" + handle
            usernameLabel.text = "This user has not yet been claimed"
        case .none:
            break
        }
    }
    
    //MARK: - DB Calls
    
    func loadUser() {
        guard user == nil, status != .loaded else { return } //user already provided on creation
        
        if let userNumber = userPhoneNumberForLoading {
            Task {
                do {
                    let backendUser = try await UsersService.singleton.loadAndCacheUser(phoneNumber: userNumber)
                    getProfileDataForUserId(backendUser.id, fromPhoneNumber: true)
                } catch {
                    CustomSwiftMessages.displayError(error)
                    status = .nonexisting
                }
            }
        } else if let userId = userIdForLoading {
            getProfileDataForUserId(userId, fromPhoneNumber: false)
        }
    }
    
    func getProfileDataForUserId(_ userId: Int, fromPhoneNumber: Bool) {
        if let cachedUser = UsersService.singleton.getPotentiallyCachedUser(userId: userId) {
            user = cachedUser
            status = .loaded
            return
        }
        
        fetchProfileDataForUserId(userId, fromPhoneNumber: fromPhoneNumber)
    }
    
    func fetchProfileDataForUserId(_ userId: Int, fromPhoneNumber: Bool) {
        status = .loading
        Task {
            do {
                user = try await UsersService.singleton.loadAndCacheUser(userId: userId)
                status = .loaded
            } catch {
                status = fromPhoneNumber ? .notclaimed : .nonexisting
                CustomSwiftMessages.displayError(error)
            }
        }
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
