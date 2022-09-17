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
    @IBOutlet weak var profilePicButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var friendStatusView: UIView!
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    //Data
    var user: ThumbnailReadOnlyUser?
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
    
    //OOOOHH ADAM: instead of a default black icon, show their character
    
    //MARK: - Constructors
    
    class func create(for user: ThumbnailReadOnlyUser) -> ProfileViewController {
        let profileVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Profile) as! ProfileViewController
        profileVC.user = user
        profileVC.status = .loading
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
            profilePicButton.imageView?.becomeProfilePicImageView(with: user.profilePic)
            nameLabel.text = user.full_name
            usernameLabel.text = user.username
            verifiedImageView.isHidden = !user.is_verified
        case .loading:
            nameLabel.text = "loading..."
            usernameLabel.text = ""
        case .nonexisting:
            guard let handle = userHandleForLoading else { return }
            profilePicButton.setImage(Constants.defaultProfilePic, for: .normal)
            nameLabel.text = "this user does not exist"
            usernameLabel.text = handle.filter({ $0 != "@" })
        case .notclaimed:
            guard let handle = userHandleForLoading else { return }
            profilePicButton.setImage(Constants.defaultProfilePic, for: .normal)
            nameLabel.text = "this account has not yet been claimed"
            usernameLabel.text = handle.filter({ $0 != "@" })
        case .none:
            break
        }
    }
    
    //MARK: - DB Calls
    
    func loadUser() {
        guard status != .loaded else { return } //user already provided on creation
        
        Task {
            if let userNumber = userPhoneNumberForLoading {
                do {
                    guard let backendUser = try await UsersService.singleton.loadAndCacheUser(phoneNumber: userNumber) else {
                        status = .notclaimed
                        return
                    }
                    await getProfileDataForUserId(backendUser.id)
                } catch {
                    CustomSwiftMessages.displayError(error)
                }
            } else if let userId = userIdForLoading { //loading frontenduser AND profilepic
                await getProfileDataForUserId(userId)
            } else if let user = user { //loading profile pic
                await getProfileDataForUserId(user.id)
            }
        }
    }
    
    func getProfileDataForUserId(_ userId: Int) async {
        status = .loading
        do {
            if let cachedUser = await UsersService.singleton.getPotentiallyCachedUser(userId: userId) {
                user = cachedUser
            } else {
                user = try await UsersService.singleton.loadAndCacheUser(userId: userId)
            }
            let loadedUser = user!
            if let cachedPic = await UsersService.singleton.getPotentiallyCachedProfilePic(userId: userId) {
                user?.profilePic = cachedPic
            } else {
                user?.profilePic = try await  UsersService.singleton.loadAndCacheProfilePic(frontendUser: loadedUser)
            }
            status = .loaded
        } catch {
            status = .nonexisting
            CustomSwiftMessages.displayError(error)
        }
    }
    
    //MARK: User Interaction
    
    @IBAction func cancelButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func moreButtonDidPressed(_ sender: UIButton) {
        
    }
    
    @IBAction func profilePicDidPressed(_ sender: UIButton) {
        guard let profilePic = user?.profilePic else { return }
        let photoDetailVC = PhotoDetailViewController.create(photo: profilePic)
        photoDetailVC.modalPresentationStyle = .fullScreen
        present(photoDetailVC, animated: true)
    }
}
