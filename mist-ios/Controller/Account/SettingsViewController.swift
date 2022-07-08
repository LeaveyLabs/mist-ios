//
//  SettingsViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

//
//  SettingsViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/31.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SettingsTapDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var settings = [Setting]()
    
    //MARK: - Initialization
    
    class func create(settings: [Setting]) -> SettingsViewController {
        let settingVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Settings) as! SettingsViewController
        settingVC.settings = settings
        return settingVC
    }
            
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        registerNibs()
        setupBackButton()
    }
    
    func setupBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
    }
    
    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Setup
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 50
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
            tableView.sectionHeaderHeight = 10
        }
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension //necessary when using constraints within cells
    }
    
    func registerNibs() {
        let settingNib = UINib(nibName: String(describing: SettingCell.self), bundle: nil);
        tableView.register(settingNib, forCellReuseIdentifier: String(describing: SettingCell.self))
    }
    
    //MARK: - Table View DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingCell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingCell.self), for: indexPath) as! SettingCell
        settingCell.configure(setting: settings[indexPath.section])
        return settingCell
    }
    
    //MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let selectedSetting = settings[indexPath.section]
        selectedSetting.tapAction(with: self)
    }

}
