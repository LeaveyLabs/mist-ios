//
//  SettingsViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/31.
//

import UIKit
import SafariServices

enum AccountSections: Int, CaseIterable {
    case profile, friends, posts, settings, more, logout
    
    var displayName : String {
        switch self {
        case .profile:
            return "PROFILE"
        case .friends:
            return "FRIENDS"
        case .posts:
            return "POSTS"
        case .settings:
            return "SETTINGS"
        case .more:
            return "MORE"
        case .logout:
            return ""
        }
    }
    
    var settingsCount: Int {
        switch self {
        case .profile:
            return Profile.allCases.count
        case .friends:
            return Friends.allCases.count
        case .posts:
            return Posts.allCases.count
        case .settings:
            return Settings.allCases.count
        case .more:
            return More.allCases.count
        case .logout:
            return 1
        }
    }

    enum Profile: Int, CaseIterable {
        case profile
    }
    enum Friends: Int, CaseIterable {
        case addFriends, myFriends
    }
    enum Posts: Int, CaseIterable {
        case submissions, mentions, favorites
    }
    enum Settings: Int, CaseIterable {
        case email, phoneNumber, password //, notifications
    }
    enum More: Int, CaseIterable {
        case rateMist, faq, legal, contactUs
    }
}


class MyAccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var accountTableView: UITableView!
    
    var rerenderProfileCallback: (() -> Void)!
        
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        registerNibs()
    }
    
    //MARK: - Setup
    
    func setupTableView() {
        accountTableView.delegate = self
        accountTableView.dataSource = self
        accountTableView.estimatedRowHeight = 50
        accountTableView.estimatedSectionFooterHeight = 20
        accountTableView.estimatedSectionHeaderHeight = 20
        accountTableView.sectionHeaderTopPadding = 15
        accountTableView.rowHeight = UITableView.automaticDimension //necessary when using constraints within cells
    }
    
    func registerNibs() {
        let myProfileNib = UINib(nibName: Constants.SBID.Cell.MyProfile, bundle: nil);
        accountTableView.register(myProfileNib, forCellReuseIdentifier: Constants.SBID.Cell.MyProfile);
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.SBID.Segue.ToMyProfileSetting {
            let myProfileSettingViewController = segue.destination as! MyProfileSettingViewController
            myProfileSettingViewController.rerenderProfileCallback = {
                self.accountTableView.reloadData()
            }
        }
    }
    
    //MARK: - User Interaction
     
    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        rerenderProfileCallback()
        self.dismiss(animated: true, completion: nil) //bc it's the nav controller's root vc
    }
    
    //MARK: - Table View DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return AccountSections.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AccountSections.init(rawValue: section)!.settingsCount
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return AccountSections.init(rawValue: section)!.displayName
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : UITableViewCell
        let settingsSection = AccountSections.init(rawValue: indexPath.section)!
        switch settingsSection {
        case .profile:
            let profileSettings = AccountSections.Profile.init(rawValue: indexPath.row)!
            switch profileSettings {
            case .profile:
                cell = accountTableView.dequeueReusableCell(withIdentifier: Constants.SBID.Cell.MyProfile, for: indexPath) as! MyProfileCell
            }
        case .friends:
            let friendsSection = AccountSections.Friends.init(rawValue: indexPath.row)!
            switch friendsSection {
            case .addFriends:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "person.badge.plus")
                cell.textLabel?.text = "Add Friends"
                cell.detailTextLabel?.text = "6"
            case .myFriends:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "person.2")
                cell.textLabel?.text = "My Friends"
                cell.detailTextLabel?.text = "30"
            }
        case .posts:
            let postsSection = AccountSections.Posts.init(rawValue: indexPath.row)!
            switch postsSection {
            case .submissions:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "plus")
                cell.textLabel?.text = "Submissions"
                cell.detailTextLabel?.text = "2"
            case .mentions:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "at")
                cell.textLabel?.text = "Mentions"
                cell.detailTextLabel?.text = "1"
            case .favorites:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "bookmark")
                cell.textLabel?.text = "Favorites"
                cell.detailTextLabel?.text = "5"
            }
        case .settings:
            let accountSettings = AccountSections.Settings.init(rawValue: indexPath.row)!
            switch accountSettings {
            case .email:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "envelope")
                cell.textLabel?.text = "Email"
                cell.detailTextLabel?.text = "adamnova@usc.edu"
                cell.accessoryType = .none //phone number cant be changed
                cell.selectionStyle = .none // **
            case .phoneNumber:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "phone")
                cell.textLabel?.text = "Phone Number"
                cell.detailTextLabel?.text = "(615) 975-4270"
                cell.accessoryType = .none //phone number cant be changed
                cell.selectionStyle = .none // **
            case .password:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "lock")
                cell.textLabel?.text = "Password"
//            case .notifications:
//                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
//                cell.imageView?.image = UIImage(systemName: "bell")
//                cell.textLabel?.text = "Notifications"
            }
        case .more:
            let moreSettings = AccountSections.More.init(rawValue: indexPath.row)!
            switch moreSettings {
            case .rateMist:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "star")
                cell.textLabel?.text = "Rate Mist"
            case .faq:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "questionmark.circle")
                cell.textLabel?.text = "FAQ"
            case .legal:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "doc.plaintext")
                cell.textLabel?.text = "Legal"
            case .contactUs:
                cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.imageView?.image = UIImage(systemName: "message")
                cell.textLabel?.text = "Contact Us"
            }
        case .logout:
            cell = accountTableView.dequeueReusableCell(withIdentifier: "SettingsLogoutCell", for: indexPath)
        }
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        return cell
    }
    
    //MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let settingsSection = AccountSections.init(rawValue: indexPath.section) else { return }
        switch settingsSection {
        case .profile:
            performSegue(withIdentifier: Constants.SBID.Segue.ToMyProfileSetting, sender: nil)
        case .friends:
            let friendsSection = AccountSections.Friends.init(rawValue: indexPath.row)!
            switch friendsSection {
            case .addFriends:
                performSegue(withIdentifier: Constants.SBID.Segue.ToMyProfileSetting, sender: nil)
            case .myFriends:
                performSegue(withIdentifier: Constants.SBID.Segue.ToMyProfileSetting, sender: nil)
            }
        case .posts:
            let postsSection = AccountSections.Posts.init(rawValue: indexPath.row)!
            switch postsSection {
            case .submissions:
                performSegue(withIdentifier: Constants.SBID.Segue.ToMyProfileSetting, sender: nil)
            case .mentions:
                performSegue(withIdentifier: Constants.SBID.Segue.ToMyProfileSetting, sender: nil)
            case .favorites:
                performSegue(withIdentifier: Constants.SBID.Segue.ToMyProfileSetting, sender: nil)
            }
        case .settings:
            let accountSettings = AccountSections.Settings.init(rawValue: indexPath.row)!
            switch accountSettings {
            case .email:
                break
            case .phoneNumber:
                break
            case .password:
                performSegue(withIdentifier: Constants.SBID.Segue.ToPasswordSetting, sender: nil)
//            case .notifications:
//                performSegue(withIdentifier: Constants.SBID.Segue.ToNotificationsSetting, sender: nil)
            }
        case .more:
            let moreSettings = AccountSections.More.init(rawValue: indexPath.row)!
            switch moreSettings {
            case .rateMist:
                openURL(URL(string: "https://getmist.app")!)
            case .faq:
                openURL(URL(string: "https://getmist.app")!)
            case .legal:
                openURL(URL(string: "https://getmist.app")!)
            case .contactUs:
                openURL(URL(string: "https://getmist.app")!)
            }
        case .logout:
            handleLogoutButtonPressed()
        }
    }
    
    //MARK: - Helpers
    
    func openURL(_ url: URL) {
        let webViewController = SFSafariViewController(url: url)
        webViewController.preferredControlTintColor = .systemBlue
        present(webViewController, animated: true)
    }
    
    func handleLogoutButtonPressed() {
        //optionally: present an alert before they log out
        Task {
            await UserService.singleton.logOut()
            transitionToStoryboard(storyboardID: Constants.SBID.SB.Auth,
                                   viewControllerID: Constants.SBID.VC.AuthNavigation,
                                   duration: 0) { _ in }
        }
    }

}
