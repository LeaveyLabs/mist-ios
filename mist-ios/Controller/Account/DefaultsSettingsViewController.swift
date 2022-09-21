//
//  CustomSettingsViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/20/22.
//

import Foundation
import UIKit
import MessageUI

class DefaultsSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SettingsTapDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var navTitle: String!
    
    //MARK: - Initialization
    
    class func create() -> DefaultsSettingsViewController {
        let settingVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.DefaultSettings) as! DefaultsSettingsViewController
        settingVC.navTitle = "defaults"
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
        setFirstSelectedCells()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = navigationController, nav.viewControllers.count > 1 {
            enableInteractivePopGesture()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disableInteractivePopGesture()
    }
    
    func setupBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)), style: .plain, target: self, action: #selector(goBack))
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
    
    func setFirstSelectedCells() {
        switch DeviceService.shared.getStartingScreen() {
        case .explore:
            (tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ToggleSettingsCell)?.setToggled(true)
        case .mistbox:
            (tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? ToggleSettingsCell)?.setToggled(true)
        }
        switch DeviceService.shared.getDefaultSort() {
        case .TRENDING:
            (tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? ToggleSettingsCell)?.setToggled(true)
        case .RECENT:
            (tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as? ToggleSettingsCell)?.setToggled(true)
        case .BEST:
            (tableView.cellForRow(at: IndexPath(row: 2, section: 1)) as? ToggleSettingsCell)?.setToggled(true)
        }
    }
    
    func registerNibs() {
        let nib = UINib(nibName: String(describing: ToggleSettingsCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: String(describing: ToggleSettingsCell.self))
    }
    
    //MARK: - Table View DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return Settings.StartingScreen.allCases.count
        } else {
            return SortOrder.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "starting screen"
        } else {
            return "sort order"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let toggleSettingsCell = tableView.dequeueReusableCell(withIdentifier: String(describing: ToggleSettingsCell.self), for: indexPath) as! ToggleSettingsCell
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                toggleSettingsCell.configure(labelText: "explore")
            case 1:
                toggleSettingsCell.configure(labelText: "mistbox")
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                toggleSettingsCell.configure(labelText: "trending")
            case 1:
                toggleSettingsCell.configure(labelText: "new")
            case 2:
                toggleSettingsCell.configure(labelText: "best")
            default:
                break
            }
        default:
            break
        }
        return toggleSettingsCell
    }
    
    //MARK: - Table View Delegate
    
//    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
//        //dont deselect if it's our cell
//        return tableView.cellForRow(at: indexPath)!.isSelected ? nil : indexPath
//    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        tableView.getAllIndexPathsInSection(section: indexPath.section).forEach { indexPath in
            (tableView.cellForRow(at: indexPath) as? ToggleSettingsCell)?.setToggled(false)
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? ToggleSettingsCell)?.setToggled(true)
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                DeviceService.shared.updateStartingScreen(.explore)
            case 1:
                DeviceService.shared.updateStartingScreen(.mistbox)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                DeviceService.shared.updateDefaultSort(.TRENDING)
            case 1:
                DeviceService.shared.updateDefaultSort(.RECENT)
            case 2:
                DeviceService.shared.updateDefaultSort(.BEST)
            default:
                break
            }
        default:
            break
        }
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
