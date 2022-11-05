//
//  SettingsViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/31.
//

import UIKit

class MyAccountViewController: SettingsViewController {
    
    @IBOutlet weak var mistFooterView: UIView!
    @IBOutlet weak var appVersionLabel: UILabel!
    
    var rerenderProfileCallback: (() -> Void)?
        
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        navigationItem.title = ""
        
        tableView.tableFooterView = mistFooterView
        appVersionLabel.text = "version " + (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)
    }
    
    override func setupTableView() {
        super.setupTableView()
        
        if #available(iOS 15.0, *) {
            tableView.estimatedSectionFooterHeight = 15
            tableView.estimatedSectionHeaderHeight = 110
            tableView.sectionHeaderTopPadding = 20
            tableView.sectionHeaderHeight = 15
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadAllData()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func reloadAllData() {
        tableView.reloadData()
        navigationItem.title = ""
    }
    
    //MARK: - User Interaction
     
    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        rerenderProfileCallback?()
        self.dismiss(animated: true, completion: nil) //bc it's the nav controller's root vc
    }
    
    //MARK: - Table View DataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return AccountSection.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, AccountSection.init(rawValue: section)!.settings.count)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return AccountSection.init(rawValue: section)!.displayName
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingsSection = AccountSection.init(rawValue: indexPath.section)!
        let settingCell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingCell.self), for: indexPath) as! SettingCell
        settingCell.configure(setting: settingsSection.settings[indexPath.row])
        return settingCell
    }
    
    //MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let settingsSection = AccountSection.init(rawValue: indexPath.section)!
        settingsSection.settings[indexPath.row].tapAction(with: self)
    }

}
