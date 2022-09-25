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
    
    @IBOutlet weak var answeredStackView: UIStackView!
    @IBOutlet weak var answeredImageView: UIImageView!
    @IBOutlet weak var answeredTitleButton: UIButton!
    @IBOutlet weak var answeredSubtitleLabel: UILabel!
    
    @IBOutlet weak var promptsStackView: UIStackView!
    @IBOutlet weak var promptOne: CollectibleView!
    @IBOutlet weak var promptTwo: CollectibleView!
    @IBOutlet weak var promptThree: CollectibleView!
    
    @IBOutlet weak var collectiblesLabel: UILabel!
    @IBOutlet weak var collectiblesBackgroundView: UIView!
    
    var promptViews: [CollectibleView] {
        return [promptOne, promptTwo, promptThree]
    }

    var todaysPrompts: [Int] {
        return UserService.singleton.getTodaysPrompts()
    }
    
    //Other
    var currentLayout: PromptsLayout = .normal
    var hasAppearedOnce = false

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupLabelsAndButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBadges()
        updateUI()
    }
    
    func updateBadges() {
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
        
        //collectiblesButton
        collectiblesBackgroundView.applyLightMediumShadow()
        collectiblesBackgroundView.roundCornersViaCornerRadius(radius: 8)
        let keywordsTap = UITapGestureRecognizer(target: self, action: #selector(didPressCollectiblesButton))
        collectiblesBackgroundView.addGestureRecognizer(keywordsTap)
    }
    
    //MARK: - UI Updates
    
    @MainActor
    func updateUI() {
        recalculateCollectiblesCount()
        if CollectibleManager.shared.hasUserEarnedAllCollectibles {
            setupAllAnsweredLayout()
        } else if CollectibleManager.shared.hasUserEarnedACollectibleToday {
            setupAnsweredLayout()
        } else {
            setupNormalLayout()
        }
    }
    
    func setupNormalLayout() {
        currentLayout = .normal
        
        promptsStackView.isHidden = false
        titleButton.isHidden = false
        
        var viewIndex = 0
        for prompt in todaysPrompts { 
            guard CollectibleManager.shared.isValidCollectibleType(prompt) else { continue }
            promptViews[viewIndex].configureForCollectible(collectibleType: prompt, delegate: self)
            viewIndex += 1
        }
        let areSomePromptsEmpty = viewIndex < 3
        if areSomePromptsEmpty {
            for invisibleIndex in viewIndex...2 {
                promptViews[invisibleIndex].isHidden = true
            }
        }
        
        answeredStackView.isHidden = true
    }
    
    func recalculateCollectiblesCount() {
        collectiblesLabel.text = String(CollectibleManager.shared.earned_collectibles.count) + "/" + String(Collectible.COLLECTIBLES_COUNT) + " collectibles"
    }
    
    func setupAnsweredLayout() {
        currentLayout = .answered
        
        promptsStackView.isHidden = true
        titleButton.isHidden = true

        answeredStackView.isHidden = false
        answeredTitleButton.setTitle("you made someone's day!", for: .normal)
        answeredSubtitleLabel.text = "come back tomorrow at 10am\nfor three new prompts"
    }
    
    func setupAllAnsweredLayout() {
        currentLayout = .allAnswered
        
        promptsStackView.isHidden = true
        titleButton.isHidden = true

        answeredStackView.isHidden = false
        answeredTitleButton.setTitle("you've earned every collectible!", for: .normal)
        answeredSubtitleLabel.text = "you are such an incredible person 🤩"
    }
    
    //MARK: - User Interaction
    
    @objc func didPressCollectiblesButton() {
        let collectiblesVC = CollectiblesViewController.create()
        self.navigationController?.pushViewController(collectiblesVC, animated: true)
    }
    
    @IBAction func didPressLearnMoreButton(_ sender: UIButton) {
        let learnMoreVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.WhatIsPrompts) as! WhatIsPromptsViewController
        present(learnMoreVC, animated: true)
    }
}

//MARK: - MistboxCellDelegate

extension PromptsViewController: CollectibleViewDelegate {
    
    func collectibleDidTapped(type: Int) {
        let newPostNav = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewPostNavigation) as! UINavigationController
        newPostNav.modalPresentationStyle = .fullScreen
        (newPostNav.topViewController as! NewPostViewController).collectibleType = type
        present(newPostNav, animated: true)
    }
    
}
