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
    
    override var posts: [Post] {
        switch setting {
        case .submissions:
            return PostService.singleton.getSubmissions()
        case .mentions:
            return PostService.singleton.getMentions()
        case .favorites:
            return PostService.singleton.getFavorites()
        default:
            return []
        }
    }
    
    //MARK: - Initialization
    
    class func create(setting: Setting) -> CustomExploreParentViewController? {
        guard setting == .favorites || setting == .submissions || setting == .mentions else { return nil }
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
        renderNewPostsOnFeedAndMap(withType: .newSearch) //using newSearch in order to force a relocation of the map
        if setting == .mentions {
            print("SETITNG DID VIEW METNIONS")
            DeviceService.shared.didViewMentions()
        }
    }
    
    func setupTitleLabel() {
        let titleLabel = exploreFeedVC.navStackView.arrangedSubviews.first(where: { $0 .isKind(of: UILabel.self )}) as? UILabel
        titleLabel?.text = setting.displayName
    }
    
    func setupBackButton() {
        let backButton = UIButton()
        let backImage = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default))!
        backButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        backButton.addTarget(self, action: #selector(backButtonDidTapped(_:)), for: .touchUpInside)
        backButton.setImage(backImage, for: .normal)
        exploreFeedVC.navStackView.insertArrangedSubview(backButton, at: 0)
    }
    
    //MARK: - User Interaction

    @objc func backButtonDidTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
}


