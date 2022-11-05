//
//  MyActivityViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/10/12.
//

import Foundation
import UIKit

class MyActivityViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UIView!

    var rerenderProfileCallback: (() -> Void)?
        
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNibs()
        setupTableView()
        navigationItem.title = "account"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)), style: .plain, target: self, action: #selector(cancelButtonDidPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)), style: .plain, target: self, action: #selector(ellipsisButtonDidPressed(_:)))
        navBar.applyLightBottomOnlyShadow()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadAllData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func reloadAllData() {
        tableView.reloadData()
        navigationItem.title = "account"
    }
    
    //MARK: - Setup
    
    func setupTableView() {
        tableView.setupTableViewSectionShadows(behindView: view, withBGColor: Constants.Color.offWhite)

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
        
        if #available(iOS 15.0, *) {
            tableView.estimatedSectionFooterHeight = 15
            tableView.estimatedSectionHeaderHeight = 110
            tableView.sectionHeaderTopPadding = 20
            tableView.sectionHeaderHeight = 15
        }
    }
    
    func registerNibs() {
        let myProfileNib = UINib(nibName: String(describing: ProfileCell.self), bundle: nil)
        tableView.register(myProfileNib, forCellReuseIdentifier: String(describing: ProfileCell.self))
    }
    
    //MARK: - User Interaction
     
    @IBAction func cancelButtonDidPressed(_ sender: UIBarButtonItem) {
        rerenderProfileCallback?()
        dismiss(animated: true)
    }
    
    @IBAction func ellipsisButtonDidPressed(_ sender: UIBarButtonItem) {
        let myAccountVC = storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccount) as! MyAccountViewController
        navigationController?.pushViewController(myAccountVC, animated: true)
    }
    
    //MARK: - Table View DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let profileCell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileCell.self), for: indexPath) as! ProfileCell
        profileCell.configure(profileType: ProfileCell.ProfileType.init(rawValue: indexPath.row)!)
        return profileCell
    }
    
    //MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0 {
            if indexPath.section == 0 {
                let updateprofileVC = UpdateProfileSettingViewController.create()
                navigationController?.pushViewController(updateprofileVC, animated: true)
            } else {
                //do nothing, for now
            }
        } else {
            //do nothing
        }
    }

}

extension MyActivityViewController: UITableViewDataSource, UITableViewDelegate {
    
}
