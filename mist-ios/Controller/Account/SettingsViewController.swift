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
    var navTitle: String!
    var settings = [Setting]()
    
    //MARK: - Initialization
    
    class func create(settings: [Setting], title: String) -> SettingsViewController {
        let settingVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.Settings) as! SettingsViewController
        settingVC.settings = settings
        settingVC.navTitle = title
        return settingVC
    }
            
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        registerNibs()
        setupBackButton()
        navigationItem.title = navTitle
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
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
            tableView.sectionHeaderHeight = 5
        }
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension //necessary when using constraints within cells
    }
    
    func registerNibs() {
        let settingNib = UINib(nibName: String(describing: SettingCell.self), bundle: nil)
        tableView.register(settingNib, forCellReuseIdentifier: String(describing: SettingCell.self))
        let feedbackNib = UINib(nibName: String(describing: FeedbackFormCell.self), bundle: nil)
        tableView.register(feedbackNib, forCellReuseIdentifier: String(describing: FeedbackFormCell.self))
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
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard
            let header:UITableViewHeaderFooterView = view as? UITableViewHeaderFooterView,
            let textLabel = header.textLabel
        else { return }
        //textLabel.font.pointSize is 13, seems kinda small
        textLabel.font = UIFont(name: Constants.Font.Roman, size: 15)
        textLabel.text = textLabel.text?.lowercased()
    }

}
