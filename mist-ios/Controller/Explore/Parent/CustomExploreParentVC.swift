//
//  CustomExploreParentVC.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/31/22.
//

import Foundation

class CustomExploreParentViewController: ExploreParentViewController {
    
    //MARK: - Properties
    
    var setting: Setting!
    var feedBottomConstraint: NSLayoutConstraint!
    
    //MARK: - Initialization
    
    class func create(setting: Setting) -> CustomExploreParentViewController? {
        guard setting == .favorites || setting == .submissions || setting == .mentions || setting == .mistbox else { return nil }
        let vc = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.CustomExploreParent) as! CustomExploreParentViewController
        vc.setting = setting
        return vc
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitleLabel()
        setupBackButton()
        navigationController?.fullscreenInteractivePopGestureRecognizer(delegate: self)
        renderNewPostsOnFeedAndMap(withType: .newSearch, customSetting: setting) //using newSearch in order to force a relocation of the map
    }
    
    func setupTitleLabel() {
        let titleLabel = exploreFeedVC.navStackView.arrangedSubviews.first(where: { $0 .isKind(of: UILabel.self )}) as? UILabel
        titleLabel?.text = setting.displayName
    }
    
    func setupBackButton() {
        let backButton = UIButton()
        let backImage = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default))!
        backButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        backButton.addTarget(self, action: #selector(backButtonDidTapped(_:)), for: .touchUpInside)
        backButton.setImage(backImage, for: .normal)
        exploreFeedVC.navStackView.insertArrangedSubview(backButton, at: 0)
    }
    
    //MARK: - User Interaction

    @objc func backButtonDidTapped(_ sender: UIButton) {
        handleBackButtonTap()
    }
    
}


