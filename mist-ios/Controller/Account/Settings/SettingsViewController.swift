//
//  SettingsViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/31.
//

import UIKit
import SafariServices

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var settingsTableView: UITableView!
    
    var sections = [[String]]()
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
//        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.size.height / 2
//        profilePictureImageView.layer.cornerCurve = .continuous
        
        super.viewDidLoad()
        configureSettings()
        setupTableView()
    }
    
    //MARK: - Setup
    
    func configureSettings() {
        sections.append(["ProfilePic", "Username", "Name"])
        sections.append(["Email", "Phone Number", "Password", "Notifications"])
        sections.append(["Rate Mist", "Share Mist", "FAQ", "Legal", "Contact Us"])
        sections.append(["Logout"])
    }
    
    func setupTableView() {
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.estimatedRowHeight = 50;
        settingsTableView.sectionHeaderTopPadding = 15
        settingsTableView.rowHeight = UITableView.automaticDimension; //necessary when using constraints within cells
    }
    
    // MARK: - Navigation
    
    
    //MARK: - User Interaction
     
    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        //settings view controller is the root view controller of the navigation controller
        //so instead of popping from the stack, just dismiss self
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Table View DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Profile"
        case 1:
            return "Account"
        case 2:
            return "More"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : UITableViewCell
        switch indexPath.section {
        //Profile
        case 0:
            switch indexPath.row {
            case 0:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsProfilePicture2Cell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            case 1:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                cell.textLabel?.text = "Username"
                cell.detailTextLabel?.text = "@adamvnovak"
            case 2:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                cell.textLabel?.text = "Name"
                cell.detailTextLabel?.text = "Adam Novak"
            default:
                //TODO: throw error. should never reach this
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
            }
        //Account
        case 1:
            switch indexPath.row {
            case 0:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                cell.textLabel?.text = "Email"
                cell.detailTextLabel?.text = "adamnova@usc.edu"
                cell.accessoryType = .none //phone number cant be changed
                cell.selectionStyle = .none // **
            case 1:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                cell.textLabel?.text = "Phone Number"
                cell.detailTextLabel?.text = "(615) 975-4270"
                cell.accessoryType = .none //phone number cant be changed
                cell.selectionStyle = .none // **
            case 2:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                cell.textLabel?.text = "Password"
                cell.detailTextLabel?.text = ""
            case 3:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                cell.textLabel?.text = "Notifications"
                cell.detailTextLabel?.text = ""
            default:
                //TODO: throw error. should never reach this
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
            }
        //More
        case 2:
            switch indexPath.row {
            case 0:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                cell.imageView?.image = UIImage(systemName: "star")
                cell.textLabel?.text = "Rate Mist"
                cell.detailTextLabel?.text = ""
            case 1:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                cell.imageView?.image = UIImage(systemName: "link")
                cell.textLabel?.text = "getmist.app/adamvnovak"
                cell.detailTextLabel?.text = ""
            case 2:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                cell.imageView?.image = UIImage(systemName: "questionmark.circle")
                cell.textLabel?.text = "FAQ"
                cell.detailTextLabel?.text = ""
            case 3:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                cell.imageView?.image = UIImage(systemName: "doc.plaintext")
                cell.textLabel?.text = "Legal"
                cell.detailTextLabel?.text = ""
            case 4:
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                cell.imageView?.image = UIImage(systemName: "message")
                cell.textLabel?.text = "Contact Us"
                cell.detailTextLabel?.text = ""
            default:
                //TODO: throw error. should never reach this
                cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
            }
        //Logout
        case 3:
            cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsLogoutCell", for: indexPath)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        default:
            //TODO: throw error. should never reach this
            cell = settingsTableView.dequeueReusableCell(withIdentifier: "SettingsSettingCell", for: indexPath)
        }
        return cell
    }
    
    //MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                break //they must click on the actual image
            case 1:
                performSegue(withIdentifier: Constants.SBID.Segue.ToUsernameSetting, sender: nil)
            default:
                //TODO: change sender?
                //TODO: performSegue via nav controller vs self? via navcontroller not working
                performSegue(withIdentifier: Constants.SBID.Segue.ToNameSetting, sender: nil)
            }
        case 1:
            switch indexPath.row {
            case 0:
                break; //email
            case 1:
                break; //phone number
            case 2:
                performSegue(withIdentifier: Constants.SBID.Segue.ToPasswordSetting, sender: nil)
            default: //case 3
                performSegue(withIdentifier: Constants.SBID.Segue.ToNotificationsSetting, sender: nil)
            }
            break; //imageview
        default: //case 2
            switch indexPath.row {
            default:
                break //nothing fofr now
            }
        }
    }
    
    //MARK: - Helpers
    
    func openURL(_ url: URL) {
        let webViewController = SFSafariViewController(url: url)
        webViewController.preferredControlTintColor = .systemBlue
        present(webViewController, animated: true)
    }

}

//reduces the width of uitableviewcells
//class CustomTableViewCell: UITableViewCell {
//    override var frame: CGRect {
//        get {
//            return super.frame
//        }
//        set (newFrame) {
//            print("setting")
//            let inset: CGFloat = 15
//            var frame = newFrame
//            frame.origin.x += inset
//            frame.size.width -= 2 * inset
//            super.frame = frame
//        }
//    }
//}
