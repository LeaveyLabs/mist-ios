//
//  MistboxViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import Foundation
import UIKit

class MistboxViewController: UIViewController {
    
    @IBOutlet weak var customNavBar: CustomNavBar!
    
    @IBOutlet weak var seeMistsView: UIView!
    @IBOutlet weak var mistboxHeaderLabel: UILabel!
    @IBOutlet weak var mistboxCountLabel: UILabel!
    @IBOutlet weak var updateKeywordsView: UIView!
    
    @IBOutlet weak var circularProgressView: CircularProgressView!
    @IBOutlet weak var countdownNumberLabel: UILabel!
    @IBOutlet weak var countdownWordLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    
    let graphicImageView = UIImageView(image: UIImage(named: "mistbox-graphic-nowords-1")!)
    
    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        MistboxManager.shared.configureMistboxTimes()
        addFloatingButton()
        setupNavBar()
        reconfigureLayout()
        setupCountdownTimer()
        commonSetup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    //MARK: - Initial setup
    
    func commonSetup() {
        mistboxCountLabel.minimumScaleFactor = 0.5
        circularProgressView.applyMediumShadow()
        seeMistsView.applyLightMediumShadow()
        updateKeywordsView.applyLightMediumShadow()
        seeMistsView.layer.cornerRadius = 10
        seeMistsView.layer.cornerCurve = .continuous
        updateKeywordsView.layer.cornerRadius = 10
        updateKeywordsView.layer.cornerCurve = .continuous
        seeMistsView.subviews.forEach { view in
            view.layer.shadowOpacity = 0
        }
        updateKeywordsView.subviews.forEach { view in
            view.layer.shadowOpacity = 0
        }
        
        let keywordsTap = UITapGestureRecognizer(target: self, action: #selector(didPressKeywordsButton))
        updateKeywordsView.addGestureRecognizer(keywordsTap)
        let mistsTap = UITapGestureRecognizer(target: self, action: #selector(didPressMistboxButton))
        seeMistsView.addGestureRecognizer(mistsTap)
    }
    
    @MainActor
    func reconfigureLayout() {
        if MistboxManager.shared.hasUserActivatedMistbox {
            setupMistboxLayout()
        } else {
            setupWelcomeLayout()
        }
    }
    
    func setupNavBar() {
        navigationController?.isNavigationBarHidden = true
        view.addSubview(customNavBar)
        customNavBar.configure(title: "mistbox", leftItems: [.title], rightItems: [.profile], delegate: self)
    }
    
    func setupWelcomeLayout() {
        circularProgressView.isHidden = true
        updateKeywordsView.isHidden = true
        mistboxHeaderLabel.isHidden = true
        mistboxCountLabel.text = "setup your keywords to start receiving a daily mistbox"
        learnMoreButton.setTitle("what's a mistbox?", for: .normal)
        setupGraphicImageView()
    }
    
    func setupGraphicImageView() {
        view.addSubview(graphicImageView)
        graphicImageView.translatesAutoresizingMaskIntoConstraints = false
        graphicImageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            graphicImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            graphicImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            graphicImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            graphicImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0),
        ])
    }
    
    func setupMistboxLayout() {
        circularProgressView.isHidden = false
        updateKeywordsView.isHidden = false
        mistboxHeaderLabel.isHidden = false
        updateCircularProgressViewAndLabels()
        learnMoreButton.setTitle("until your new mistbox", for: .normal)
        graphicImageView.isHidden = true
    }
    
    //MARK: - Countdown updates
    
    func setupCountdownTimer() {
        Task {
            while true {
                DispatchQueue.main.async {
                    self.updateCircularProgressViewAndLabels()
                }
                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
            }
        }
    }
    
    func updateCircularProgressViewAndLabels() {
        MistboxManager.shared.configureMistboxTimes()
        if MistboxManager.shared.hasUnopenedMistbox {
            setupForReadyMistbox()
        } else {
            setupForCountdown()
        }
    }
    
    func setupForReadyMistbox() {
        //TODO: "full bar with OMG YOUR MISTBOX IS READYYYY"
    }
    
    func setupForCountdown() {
        let timeUntilMistbox = MistboxManager.shared.timeUntilNextMistbox
        if timeUntilMistbox.hours > 0 {
            countdownWordLabel.text = "hours"
            countdownNumberLabel.text = String(timeUntilMistbox.hours)
        } else if timeUntilMistbox.minutes > 0 {
            countdownWordLabel.text = "minutes"
            countdownNumberLabel.text = String(timeUntilMistbox.minutes)
        } else if timeUntilMistbox.seconds > 0 {
            countdownWordLabel.text = "seconds"
            countdownNumberLabel.text = String(timeUntilMistbox.seconds)
        }
        circularProgressView.progress = MistboxManager.shared.percentUntilNextMistbox
    }
    
    //MARK: - UserInteraction
    
    @objc func didPressMistboxButton() {
        guard MistboxManager.shared.hasUserActivatedMistbox else {
            didPressKeywordsButton()
            return
        }
        guard let mistboxExplore = CustomExploreViewController.create(setting: .mistbox) else { return }
        navigationController?.pushViewController(mistboxExplore, animated: true)
        MistboxManager.shared.handleOpenMistbox()
    }
    
    @objc func didPressKeywordsButton() {
        if MistboxManager.shared.hasUserActivatedMistbox {
            sendToKeywordsVC()
            return
        }
        let center  = UNUserNotificationCenter.current()
//        center.delegate = self
        center.getNotificationSettings(completionHandler: { [self] (settings) in
            switch settings.authorizationStatus {
            case .authorized:
                sendToKeywordsVC()
            case .denied, .notDetermined:
                CustomSwiftMessages.showPermissionRequest(permissionType: .mistboxNotifications) { approved in
                    guard approved else { return }
                    if settings.authorizationStatus == .denied {
                        CustomSwiftMessages.showSettingsAlertController(title: "enable notifications in settings", message: "", on: self)
                    } else {
                        center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
                            guard granted else { return }
                            UIApplication.shared.registerForRemoteNotifications()
                            self.sendToKeywordsVC()
                        }
                    }
                }
            default:
                break //when will this occur?? idk
            }
        })
    }
    
    func sendToKeywordsVC() {
//        DispatchQueue.main.async {
//            let asdf = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.NewPost)
//                self.navigationController?.pushViewController(asdf, animated: true)
//        }
        DispatchQueue.main.async {
            let keywordsVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.EnterKeywords)
            self.navigationController?.pushViewController(keywordsVC, animated: true, completion: {
                DispatchQueue.main.async {
                    self.reconfigureLayout()
                }
            })
        }
    }

}

extension MistboxViewController: CustomNavBarDelegate { //nothing additional needed here
    
}
