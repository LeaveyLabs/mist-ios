//
//  MistboxViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import Foundation
import UIKit

class MistboxViewController: UIViewController {
    
    enum MistboxLayout: String, CaseIterable {
        case countdown, welcome, unopened
    }
    
    //UI
    @IBOutlet weak var customNavBar: CustomNavBar!
    @IBOutlet weak var seeMistsView: UIView!
    @IBOutlet weak var mistboxHeaderLabel: UILabel!
    @IBOutlet weak var mistboxCountLabel: UILabel!
    @IBOutlet weak var updateKeywordsView: UIView!
    @IBOutlet weak var keywordsLabel: UILabel!
    @IBOutlet weak var circularProgressView: CircularProgressView!
    @IBOutlet weak var countdownNumberLabel: UILabel!
    @IBOutlet weak var countdownWordLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var graphicImageView: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var openIcon: UIImageView!
    
    //Other
    var currentLayout: MistboxLayout = .welcome
    var isFirstLoad = true
    var isProgressViewAnimating = true
    
    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        MistboxManager.shared.configureMistboxTimes()
        setupNavBar()
        setupCountdownTimer()
        commonSetup()
        setupGestureRecognizers()
        configureCircleLayer()
        circularProgressView.progressLayer.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard isFirstLoad else { return }
        isFirstLoad = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.startCircleAnimation()
        }
    }
    
//    private var circleLayer = circularProgressView.progressLayer

    private func configureCircleLayer() {
//        let radius = min(circularProgressView.bounds.width, circularProgressView.bounds.height) / 2
//
//
//        circularProgressView.progressLayer.
//        circleLayer.strokeColor = Constants.Color.mistPurple.withAlphaComponent(0.1).cgColor
//        circleLayer.fillColor = UIColor.clear.cgColor
//        circleLayer.lineWidth = circularProgressView.trackLineWidth
//        circularProgressView.layer.addSublayer(circleLayer)
//
//        let center = CGPoint(x: circularProgressView.bounds.width/2, y: circularProgressView.bounds.height/2)
//        let startAngle: CGFloat = -0.25 * 2 * .pi
//        let endAngle: CGFloat = startAngle + 2 * .pi
//        circleLayer.path = UIBezierPath(arcCenter: center, radius: radius / 2, startAngle: startAngle, endAngle: endAngle, clockwise: true).cgPath
//
//        circleLayer.strokeEnd = 0
    }

    private func startCircleAnimation() {
        circularProgressView.progress = MistboxManager.shared.percentUntilNextMistbox //you have to set the final ending value of progress before you start the animation
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fromValue = 0
        animation.toValue = MistboxManager.shared.percentUntilNextMistbox
        animation.duration = 1.5
        circularProgressView.progressLayer.isHidden = false
        circularProgressView.progressLayer.add(animation, forKey: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isProgressViewAnimating = false
        }
    }
    
    //MARK: - Initial setup
    
    func commonSetup() {
        mistboxCountLabel.minimumScaleFactor = 0.5
        circularProgressView.applyLightMediumShadow()
        countdownWordLabel.layer.shadowOpacity = 0
        countdownNumberLabel.layer.shadowOpacity = 0
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
        updateKeywordCount(to: UserService.singleton.getKeywords().count)
    }
    
    func setupGestureRecognizers() {
        let keywordsTap = UITapGestureRecognizer(target: self, action: #selector(didPressKeywordsButton))
        updateKeywordsView.addGestureRecognizer(keywordsTap)
        let mistsTap = UITapGestureRecognizer(target: self, action: #selector(didPressMistboxButton))
        seeMistsView.addGestureRecognizer(mistsTap)
    }
    
    func setupNavBar() {
        navigationController?.isNavigationBarHidden = true
        view.addSubview(customNavBar)
        customNavBar.configure(title: "mistbox", leftItems: [.title], rightItems: [.profile], delegate: self)
    }
    
    //MARK: - Countdown
    
    func setupCountdownTimer() {
        Task {
            while true {
                DispatchQueue.main.async {
                    self.updateUI()
                }
                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
            }
        }
    }
    
    @MainActor
    func updateUI() {
        MistboxManager.shared.configureMistboxTimes() //just to make sure we have the right time precisely before updating the UI
        setupCountdownLayout()
        updateProgressBarAndCountdownLabel()
//        switch currentLayout {
//        case .countdown:
//            if !MistboxManager.shared.hasUserActivatedMistbox {
//                setupWelcomeLayout()
//            } else if MistboxManager.shared.hasUnopenedMistbox {
//                setupUnopenedLayout()
//            } else {
//                updateProgressBarAndCountdownLabel()
//            }
//        case .welcome:
//            if MistboxManager.shared.hasUserActivatedMistbox {
//                setupCountdownLayout()
//                updateProgressBarAndCountdownLabel()
//            }
//        case .unopened:
//            if !MistboxManager.shared.hasUnopenedMistbox {
//                setupCountdownLayout()
//                updateProgressBarAndCountdownLabel()
//            }
//        }
    }
    
    func updateProgressBarAndCountdownLabel() {
        
        //TODO: make sure that in MistboxManager, we handle using the previous vs the current mistbox right at 10am
            //both in "timeunitlnextmistbox", "percent", "currentdate" and "getmistboxcount"
        
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
        
        if !isProgressViewAnimating {
            circularProgressView.progress = MistboxManager.shared.percentUntilNextMistbox
        }
    }
    
    func updateKeywordCount(to newKeywordCount: Int) {
        keywordsLabel.text = "keywords: " + String(newKeywordCount) + "/5"
    }
    
    //MARK: - Layouts
        
    func setupWelcomeLayout() {
        currentLayout = .welcome
        
        circularProgressView.isHidden = true
        updateKeywordsView.isHidden = true
        mistboxHeaderLabel.isHidden = true
        learnMoreButton.isHidden = false
        learnMoreButton.setTitle("what's a mistbox?", for: .normal)
        graphicImageView.isHidden = true
        graphicImageView.isHidden = false
        graphicImageView.image = UIImage(named: "mistbox-graphic-nowords-1")!
        seeMistsView.backgroundColor = .white
        openIcon.tintColor = .lightGray
        mistboxCountLabel.textColor = Constants.Color.mistBlack
        mistboxHeaderLabel.textColor =  Constants.Color.mistBlack
        
        mistboxCountLabel.text = "setup your keywords to start receiving a daily mistbox"
    }
    
    func setupCountdownLayout() {
        currentLayout = .countdown
        
        circularProgressView.isHidden = false
        updateKeywordsView.isHidden = false
        mistboxHeaderLabel.isHidden = false
        learnMoreButton.isHidden = false
        learnMoreButton.setTitle("until your new mistbox", for: .normal)
        graphicImageView.isHidden = true
        seeMistsView.backgroundColor = .white
        openIcon.tintColor = .lightGray
        mistboxCountLabel.textColor = Constants.Color.mistBlack
        mistboxHeaderLabel.textColor =  Constants.Color.mistBlack
        
        mistboxHeaderLabel.text = MistboxManager.shared.currentMistboxDate
        mistboxCountLabel.text = String(PostService.singleton.getMistboxPosts().count) + " mists"
    }
    
    func setupUnopenedLayout() {
        currentLayout = .unopened
        
        circularProgressView.isHidden = true
        updateKeywordsView.isHidden = true
        mistboxHeaderLabel.isHidden = false
        learnMoreButton.isHidden = true
        graphicImageView.isHidden = false
        graphicImageView.image = UIImage(named: "auth-graphic-text-3")!
        seeMistsView.backgroundColor = .white
        openIcon.tintColor = .lightGray
        mistboxCountLabel.textColor = Constants.Color.mistBlack
        mistboxHeaderLabel.textColor =  Constants.Color.mistBlack
//        seeMistsView.backgroundColor = Constants.Color.mistLilac
//        openIcon.tintColor = .white
//        mistboxCountLabel.textColor = .white
//        mistboxHeaderLabel.textColor = .white
        
        mistboxHeaderLabel.text = MistboxManager.shared.currentMistboxDate
        mistboxCountLabel.text = String(PostService.singleton.getMistboxPosts().count) + " unopened mists"
    }
    
    //MARK: - UserInteraction
    
    @objc func didPressMistboxButton() {
        switch currentLayout {
        case .countdown, .unopened:
            guard let mistboxExplore = CustomExploreParentViewController.create(setting: .mistbox) else { return }
            navigationController?.pushViewController(mistboxExplore, animated: true)
            MistboxManager.shared.handleOpenMistbox()
        case .welcome:
            didPressKeywordsButton() //because the MistboxButton acts as the KeywordsButton
        }
    }
    
    @objc func didPressKeywordsButton() {
        switch currentLayout {
        case .countdown:
            sendToKeywordsVC()
        case .welcome:
            askForPermissionsAndSendToKeywordsVC()
        case .unopened:
            break //keywords button should be hidden while in .unopened
        }
    }
    
    func askForPermissionsAndSendToKeywordsVC() {
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
        DispatchQueue.main.async {
            let keywordsVC = EnterKeywordsViewController.create { newKeywordCount in
                self.updateKeywordCount(to: newKeywordCount)
            }
            self.navigationController?.pushViewController(keywordsVC, animated: true)
        }
    }

}

extension MistboxViewController: CustomNavBarDelegate { //nothing additional needed here
    
}
