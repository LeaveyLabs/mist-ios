//
//  CustomExploreViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/12/22.
//

import Foundation

class CustomExploreViewController: ExploreViewController {
    
    //MARK: - Properties
    
    @IBOutlet weak var headerTitleLabel: UILabel!
    var setting: Setting!
    
    //MARK: - Initialization
    
    class func create(setting: Setting) -> CustomExploreViewController? {
        if !(setting == .favorites || setting == .submissions || setting == .mentions) { return nil }
        let vc = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.CustomExplore) as! CustomExploreViewController
        vc.setting = setting
        return vc
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Remove bottom constraint on feed to safeBottomArea which was set in super
        view.constraints.first { $0.firstAnchor == feed.bottomAnchor }!.isActive = false
        NSLayoutConstraint.activate([
            feed.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        setupCustomNavigationBar()
        renderNewPostsOnFeedAndMap(withType: .newSearch, customSetting: setting) //using newSearch in order to force a relocation of the map
    }
    
    //MARK: - Setup
    
    override func setupCustomNavigationBar() {
        navigationController?.isNavigationBarHidden = true
        view.addSubview(customNavBar)
        customNavBar.configure(title: setting.displayName.lowercased(), leftItems: [.back, .title], rightItems: [.filter, .map], delegate: self)
    }
    
    //MARK: - User Interaction

    @IBAction func backButtonDidTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
}

extension CustomExploreViewController: CustomNavBarDelegate {
    
    func handleFilterButtonTap() {
        //nothing for now
    }
    
    func handleFeedButtonTap() {
        toggleButtonDidTapped()
    }
    
    func handleMapButtonTap() {
        toggleButtonDidTapped()
    }
    
    func handleSearchButtonTap() {
        presentExploreSearchController()
    }
    
}
