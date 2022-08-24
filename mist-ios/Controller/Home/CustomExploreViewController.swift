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
        makeFeedVisible()
        
        headerTitleLabel.text = setting.displayName
        renderNewPostsOnFeedAndMap(withType: .newSearch, customSetting: setting) //using newSearch in order to force a relocation of the map
    }
    
    //MARK: - User Interaction

    @IBAction func backButtonDidTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
}
