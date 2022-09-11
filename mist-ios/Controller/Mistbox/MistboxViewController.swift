//
//  MistboxViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import Foundation
import UIKit
import CenteredCollectionView

class MistboxViewController: UIViewController {
    
    enum MistboxLayout: String, CaseIterable {
        case normal, welcome, empty
    }
//    let verticalPanGesture = UIPanGestureRecognizer()
    
    // MARK: - Properties
    
    //UI
    let centeredCollectionViewFlowLayout = CenteredCollectionViewFlowLayout()
    var collectionView: PostCollectionView!
    var visibleIndexLabel = UILabel()
    
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
    @IBOutlet weak var setupMistboxBackgroundView: UIView!
    @IBOutlet weak var centerDescriptionLabel: UILabel!
    
    @IBOutlet weak var keywordsBackgroundView: UIView!
    @IBOutlet weak var keywordsLabel: UILabel!

    var posts: [Post] {
        MistboxManager.shared.getMistboxMists()
    }
    var currentVisibleIndex: Int = 0
    
    //Other
    var currentLayout: MistboxLayout = .normal
    var hasAppearedOnce = false
    var isPostPushed = false

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupNavBar()
        setupLabelsAndButtons()
        setupTabBar()
        updateUI()
    }
    
    func setupTabBar() {
        guard let tabBarController = tabBarController as? SpecialTabBarController else { return }
        tabBarController.selectedIndex = 1
        tabBarController.refreshBadgeCount()
        tabBarController.repositionBadges()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if hasAppearedOnce && !isPostPushed {
            collectionView.reloadData()
            rerenderTitleText()
            reloadVisibleIndexLabel()
        }
        if let tabVC = UIApplication.shared.windows.first?.rootViewController as? SpecialTabBarController {
            tabVC.refreshBadgeCount()
        }
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
        navigationController?.isNavigationBarHidden = true
        navBar.configure(title: "mistbox", leftItems: [.title], rightItems: [.profile])
        navBar.accountButton.addTarget(self, action: #selector(handleProfileButtonTap), for: .touchUpInside)
//        let profilePicBadgeHub = BadgeHub(view: navBar)
    }
    
    @objc func updateProfilePicBadgeHub() {
        
    }
    
    private func setupCollectionView() {
        collectionView = PostCollectionView(centeredCollectionViewFlowLayout: centeredCollectionViewFlowLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.clipsToBounds = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        view.addSubview(collectionView)
        
//        collectionView.addGestureRecognizer(verticalPanGesture)

        // register collection cells
        collectionView.register(MistboxCollectionCell.self, forCellWithReuseIdentifier: String(describing: MistboxCollectionCell.self))

        // configure layout
        let envelopeHeight = view.frame.size.height * 0.43
        let envelopeWidth = envelopeHeight * EnvelopeView.envelopeImageWidthHeightRatio
        centeredCollectionViewFlowLayout.itemSize = CGSize(
            width: envelopeWidth,
            height: envelopeHeight
        )
        let marginBetweenEnvelopeEndsAndScreenWidth: Double = Double(view.frame.size.width - envelopeWidth) / 2
        centeredCollectionViewFlowLayout.minimumLineSpacing = marginBetweenEnvelopeEndsAndScreenWidth / 2
        
        NSLayoutConstraint.activate([
            collectionView.widthAnchor.constraint(equalTo: view.widthAnchor),
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            collectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: view.frame.height * -0.02),
            collectionView.heightAnchor.constraint(equalToConstant: envelopeHeight),
        ])
    }
    
    func setupLabelsAndButtons() {
        //MistsCountLabel under the collectionview
        view.addSubview(visibleIndexLabel)
        visibleIndexLabel.translatesAutoresizingMaskIntoConstraints = false
        visibleIndexLabel.textColor = Constants.Color.mistBlack
        visibleIndexLabel.font = UIFont(name: Constants.Font.Roman, size: 14)
        NSLayoutConstraint.activate([
            visibleIndexLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            visibleIndexLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: view.frame.height * 0.013),
        ])
        
        //so that text can shrink
        titleButton.titleLabel?.minimumScaleFactor = 0.1
        titleButton.titleLabel?.numberOfLines = 1
        titleButton.titleLabel?.adjustsFontSizeToFitWidth = true
        titleButton.titleLabel?.lineBreakMode = NSLineBreakMode.byClipping
        
        //title button
        rerenderTitleText()
        
        reloadVisibleIndexLabel()
        
        //keywordsButton
        keywordsBackgroundView.applyLightMediumShadow()
        keywordsBackgroundView.roundCornersViaCornerRadius(radius: 8)
        let keywordsTap = UITapGestureRecognizer(target: self, action: #selector(didPressKeywordsButton))
        keywordsBackgroundView.addGestureRecognizer(keywordsTap)
        
        //setupMistbox
        setupMistboxBackgroundView.applyLightMediumShadow()
        setupMistboxBackgroundView.roundCornersViaCornerRadius(radius: 8)
        let learnMoreTap = UITapGestureRecognizer(target: self, action: #selector(didPressLearnMoreButton(_:)))
        setupMistboxBackgroundView.addGestureRecognizer(learnMoreTap)
    }
    
    //MARK: - UI Updates
    
    @MainActor
    func updateUI() {
        switch currentLayout {
        case .normal:
            if !MistboxManager.shared.hasUserActivatedMistbox {
                setupWelcomeLayout()
            } else if MistboxManager.shared.getMistboxMists().isEmpty {
                setupEmptyLayout()
            } else {
                setupNormalLayout()
            }
        case .welcome:
            if MistboxManager.shared.hasUserActivatedMistbox {
                setupEmptyLayout()
                //don't increment the notification request here, since this is a default one
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationsManager.shared.askForNewNotificationPermissionsIfNecessary(permission: .mistboxNotifications, onVC: self)
                }
            } else {
                setupWelcomeLayout()
            }
        case .empty:
            if !MistboxManager.shared.getMistboxMists().isEmpty {
                setupNormalLayout()
            } else if !MistboxManager.shared.hasUserActivatedMistbox { //this should never happen, but just in case we leave some bug laying around
                setupWelcomeLayout()
                
            } else {
                setupEmptyLayout()
            }
        }
    }
    
    func setupNormalLayout() {
        currentLayout = .normal
        
        centerStackView.isHidden = true
        keywordsBackgroundView.isHidden = false
        collectionView.isHidden = false
        titleButton.isHidden = false
        visibleIndexLabel.isHidden = false
    }
        
    func setupWelcomeLayout() {
        currentLayout = .welcome
        
        centerStackView.isHidden = false
        centerStackView.spacing = 20
        centerImageView.image = UIImage(named: "mistbox-graphic-nowords-1")
        centerButton.isHidden = true
        setupMistboxBackgroundView.isHidden = false
        centerDescriptionLabel.text = ""
        keywordsBackgroundView.isHidden = true
        collectionView.isHidden = true
        titleButton.isHidden = true
        visibleIndexLabel.isHidden = true
    }
    
    func setupEmptyLayout() {
        currentLayout = .empty
        
        centerStackView.isHidden = false
        centerStackView.spacing = 10
        centerImageView.image = UIImage(named: "empty-mistbox-graphic")
        centerButton.isHidden = false
        setupMistboxBackgroundView.isHidden = true
        centerDescriptionLabel.text = "when someone drops a mist containing one of your keywords, it'll appear here"
        keywordsBackgroundView.isHidden = false
        collectionView.isHidden = true
        titleButton.isHidden = true
        visibleIndexLabel.isHidden = true
    }
    
    //MARK: - User Interaction
    
    @objc func didPressKeywordsButton() {
        let keywordsVC = EnterKeywordsViewController.create()
        self.navigationController?.pushViewController(keywordsVC, animated: true)
    }
    
    @IBAction func didPressLearnMoreButton(_ sender: UIButton) {
        let learnMoreVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.WhatIsMistbox) as! WhatIsMistboxViewController
        guard currentLayout != .welcome else {
            let nav = UINavigationController(rootViewController: learnMoreVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
            return
        }
        present(learnMoreVC, animated: true)
    }
}

//MARK: - CollectionViewDelegate

//These are not being called for some reason
extension MistboxViewController: UICollectionViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        print("should")
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected Cell #\(indexPath.row)")
        if let currentCenteredPage = centeredCollectionViewFlowLayout.currentCenteredPage,
            currentCenteredPage != indexPath.row {
            centeredCollectionViewFlowLayout.scrollToPage(index: indexPath.row, animated: true)
        }
    }
        
}

//MARK: - CollectionViewDataSource

extension MistboxViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MistboxCollectionCell.self), for: indexPath) as! MistboxCollectionCell
        cell.configureForPost(post: posts[indexPath.row], delegate: self, panGesture: collectionView.panGestureRecognizer)
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let centeredPage = centeredCollectionViewFlowLayout.currentCenteredPage {
            currentVisibleIndex = centeredPage
        }
        reloadVisibleIndexLabel()
    }
    
}

//MARK: - MistboxCellDelegate

extension MistboxViewController: MistboxCellDelegate {
    
    func didSkipMist(postId: Int) {
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else { return }
        do {
            try MistboxManager.shared.skipMist(index: postIndex, postId: postId)
        } catch {
            CustomSwiftMessages.displayError(error)
        }
        
        visuallyRemoveMist(postIndex: postIndex)
    }
    
    func didOpenMist(postId: Int) {
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else { return }
        guard let post = PostService.singleton.getPost(withPostId: postId) else { return }
        do {
            try MistboxManager.shared.openMist(index: postIndex, postId: postId)
        } catch {
            CustomSwiftMessages.displayError(error)
        }
        
        isPostPushed = true
        let openedPostVC = PostViewController.createPostVC(with: post, shouldStartWithRaisedKeyboard: false, fromMistbox: true, completionHandler: {
            self.visuallyRemoveMist(postIndex: postIndex)
            self.isPostPushed = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                AppStoreReviewManager.requestReviewIfAppropriate()
            }
        })
        navigationController?.pushViewController(openedPostVC, animated: true) { [self] in
            (tabBarController as? SpecialTabBarController)?.decrementMistboxBadgeCount()
        }
        
    }
    
    //MARK: - HELPERS
    
    @MainActor
    func visuallyRemoveMist(postIndex: Int) {
        collectionView.visibleCells.forEach { cell in
            guard let cell = cell as? MistboxCollectionCell else { return }
            cell.envelopeView.rerenderOpenCount()
        }

        collectionView.performBatchUpdates({
            self.collectionView.deleteItems(at:[IndexPath(item: postIndex, section: 0)])
        }) { completed in
            guard !MistboxManager.shared.getMistboxMists().isEmpty else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
                    self.updateUI()
                }
                return
            }
            self.reloadVisibleIndexLabel()
            self.rerenderTitleText()
            
        }
    }
    
    func reloadVisibleIndexLabel() {
        visibleIndexLabel.text = String(currentVisibleIndex + 1) + "/" + String(MistboxManager.shared.getMistboxMists().count)
    }
    
    func rerenderTitleText() {
        let mistsCount = MistboxManager.shared.getMistboxMists().count
        let text = "a special delivery of " + String(mistsCount) + " mist" + (mistsCount > 1 ? "s" : "")
        let attributedText = NSMutableAttributedString(string: text, attributes: MistboxViewController.normalTitleAttributes)
        if let numberRange = text.range(of: String(mistsCount)) {
            attributedText.setAttributes(MistboxViewController.boldTitleAttributes, range: NSRange(numberRange, in: text))
        }
        titleButton.setAttributedTitle(attributedText, for: .normal)
    }
    
}
