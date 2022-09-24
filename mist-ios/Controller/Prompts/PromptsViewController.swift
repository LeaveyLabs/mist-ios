//
//  PromptsViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/23/22.
//

import Foundation
import UIKit
import CenteredCollectionView

class PromptsViewController: UIViewController {
    
    enum PromptsLayout: String, CaseIterable {
        case normal, answered, allAnswered
    }
    
    // MARK: - Properties
    
    //UI
    static let boldTitleAttributes: [NSAttributedString.Key : Any] = [
        .font: UIFont(name: Constants.Font.Heavy, size: 18)!,
        .foregroundColor: Constants.Color.mistLilac,]
    static let normalTitleAttributes: [NSAttributedString.Key : Any] = [
        .font: UIFont(name: Constants.Font.Roman, size: 18)!,
        .foregroundColor: UIColor.black,]
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var navBar: CustomNavBar!
    
    @IBOutlet weak var centerStackView: UIStackView!
    @IBOutlet weak var centerImageView: UIImageView!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var centerDescriptionLabel: UILabel!
    
    @IBOutlet weak var collectiblesStackView: UIStackView!
    
    @IBOutlet weak var collectiblesBackgroundView: UIView!
    @IBOutlet weak var collectiblesLabel: UILabel!

    var prompts: [Post] {
        MistboxManager.shared.getMistboxMists()
    }
    
    //Other
    var currentLayout: PromptsLayout = .normal
    var hasAppearedOnce = false

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupLabelsAndButtons()
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (tabBarController as? SpecialTabBarController)?.refreshBadgeCount()
        let prevCount = navBar.accountBadgeHub.getCurrentCount()
        navBar.accountBadgeHub.setCount(DeviceService.shared.unreadMentionsCount())
        if prevCount < DeviceService.shared.unreadMentionsCount() {
            navBar.accountBadgeHub.bump()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppearedOnce = true
    }
    
    
    // MARK: - Configuration
    
    func setupNavBar() {
        navBar.configure(title: "prompts", leftItems: [.title], rightItems: [.profile])
        navBar.accountButton.addTarget(self, action: #selector(handleProfileButtonTap), for: .touchUpInside)
    }
    
    func setupLabelsAndButtons() {
        //so that text can shrink
        titleButton.titleLabel?.minimumScaleFactor = 0.1
        titleButton.titleLabel?.numberOfLines = 1
        titleButton.titleLabel?.adjustsFontSizeToFitWidth = true
        titleButton.titleLabel?.lineBreakMode = NSLineBreakMode.byClipping
        
        //keywordsButton
        collectiblesBackgroundView.applyLightMediumShadow()
        collectiblesBackgroundView.roundCornersViaCornerRadius(radius: 8)
        let keywordsTap = UITapGestureRecognizer(target: self, action: #selector(didPressCollectiblesButton))
        collectiblesBackgroundView.addGestureRecognizer(keywordsTap)
    }
    
    //MARK: - UI Updates
    
    @MainActor
    func updateUI() {
        switch currentLayout {
        case .normal:
            //if they have no more collectibles available, then they answered
            //if they have 50 collectibles, they have allAnswered
            break
        case .answered:
            //if they have collectibles available, normal
            //if they have all answered, allAnswered
            break
        case .allAnswered:
            
            break
        }
    }
    
    func setupNormalLayout() {
        currentLayout = .normal
        
        centerStackView.isHidden = true
        collectiblesBackgroundView.isHidden = false
        titleButton.isHidden = false
        titleButton.alpha = 1
    }
    
    func setupAnsweredLayout() {
        currentLayout = .answered
        
        centerStackView.isHidden = false
        centerStackView.spacing = 10
        centerImageView.image = UIImage(named: "empty-mistbox-graphic")
        centerButton.isHidden = false
        centerDescriptionLabel.text = "when someone drops a mist containing one of your keywords, it'll appear here"
        collectiblesBackgroundView.isHidden = false
        titleButton.isHidden = true
    }
    
    func setupAllAnsweredLayout() {
        currentLayout = .allAnswered
        
        centerStackView.isHidden = false
        centerStackView.spacing = 20
        centerImageView.image = UIImage(named: "mistbox-graphic-nowords-1")
        centerButton.isHidden = true
        centerDescriptionLabel.text = ""
        collectiblesBackgroundView.isHidden = true
        titleButton.isHidden = true
    }
    
    //MARK: - User Interaction
    
    @objc func didPressCollectiblesButton() {
        let keywordsVC = EnterKeywordsViewController.create()
        self.navigationController?.pushViewController(keywordsVC, animated: true)
    }
    
    @IBAction func didPressLearnMoreButton(_ sender: UIButton) {
        let learnMoreVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.WhatIsMistbox) as! WhatIsMistboxViewController
        present(learnMoreVC, animated: true)
    }
}

//MARK: - MistboxCellDelegate

extension PromptsViewController: MistboxCellDelegate {
    
    func didSkipMist(postId: Int) {
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else { return }
        do {
            try MistboxManager.shared.skipMist(index: postIndex, postId: postId)
        } catch {
            CustomSwiftMessages.displayError(error)
        }
        
        visuallyRemoveMist(postIndex: postIndex)
    }
    
}
