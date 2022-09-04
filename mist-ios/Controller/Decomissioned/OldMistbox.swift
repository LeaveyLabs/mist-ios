////
////  OldMistbox.swift
////  mist-ios
////
////  Created by Adam Monterey on 9/4/22.
////
//
//import Foundation
//
//class OldMistboxViewController: UIViewController {
//    
//    enum MistboxLayout: String, CaseIterable {
//        case countdown, welcome, unopened
//    }
//    
//    //UI
//    @IBOutlet weak var customNavBar: CustomNavBar!
//    @IBOutlet weak var seeMistsView: UIView!
//    @IBOutlet weak var mistboxHeaderLabel: UILabel!
//    @IBOutlet weak var mistboxCountLabel: UILabel!
//    @IBOutlet weak var updateKeywordsView: UIView!
//    @IBOutlet weak var keywordsLabel: UILabel!
//    @IBOutlet weak var circularProgressView: CircularProgressView!
//    @IBOutlet weak var countdownNumberLabel: UILabel!
//    @IBOutlet weak var countdownWordLabel: UILabel!
//    @IBOutlet weak var learnMoreButton: UIButton!
//    @IBOutlet weak var graphicImageView: SpringImageView!
//    @IBOutlet weak var stackView: UIStackView!
//    @IBOutlet weak var openIcon: UIImageView!
//    
//    //Other
//    var currentLayout: MistboxLayout = .welcome
//    var isFirstLoad = true
//    var isProgressViewAnimating = true
//    
//    //MARK: - Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        MistboxManager.shared.updateMistboxReleaseDates()
//        setupNavBar()
//        setupCountdownTimer()
//        commonSetup()
//        setupGestureRecognizers()
//        configureCircleLayer()
//        circularProgressView.progressLayer.isHidden = true
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(true, animated: false)
//        updateUI()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        guard isFirstLoad else { return }
//        DispatchQueue.main.asyncAfter(deadline: .now() + (isFirstLoad ? 0.8 : 0.5)) {
//            self.startCircleAnimation()
//        }
//        isFirstLoad = false
//    }
//    
////    private var circleLayer = circularProgressView.progressLayer
//
//    private func configureCircleLayer() {
////        let radius = min(circularProgressView.bounds.width, circularProgressView.bounds.height) / 2
////
////
////        circularProgressView.progressLayer.
////        circleLayer.strokeColor = Constants.Color.mistPurple.withAlphaComponent(0.1).cgColor
////        circleLayer.fillColor = UIColor.clear.cgColor
////        circleLayer.lineWidth = circularProgressView.trackLineWidth
////        circularProgressView.layer.addSublayer(circleLayer)
////
////        let center = CGPoint(x: circularProgressView.bounds.width/2, y: circularProgressView.bounds.height/2)
////        let startAngle: CGFloat = -0.25 * 2 * .pi
////        let endAngle: CGFloat = startAngle + 2 * .pi
////        circleLayer.path = UIBezierPath(arcCenter: center, radius: radius / 2, startAngle: startAngle, endAngle: endAngle, clockwise: true).cgPath
////
////        circleLayer.strokeEnd = 0
//    }
//
//    private func startCircleAnimation() {
//        circularProgressView.progress = MistboxManager.shared.percentUntilNextMistbox //you have to set the final ending value of progress before you start the animation
//        let animation = CABasicAnimation(keyPath: "strokeEnd")
//        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//        animation.fromValue = 0
//        animation.toValue = MistboxManager.shared.percentUntilNextMistbox
//        animation.duration = 1.5
//        circularProgressView.progressLayer.isHidden = false
//        circularProgressView.progressLayer.add(animation, forKey: nil)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.isProgressViewAnimating = false
//        }
//    }
//    
//    //MARK: - Initial setup
//    
//    func commonSetup() {
//        mistboxCountLabel.minimumScaleFactor = 0.5
//        circularProgressView.applyLightMediumShadow()
//        countdownWordLabel.layer.shadowOpacity = 0
//        countdownNumberLabel.layer.shadowOpacity = 0
//        seeMistsView.applyLightMediumShadow()
//        updateKeywordsView.applyLightMediumShadow()
//        seeMistsView.layer.cornerRadius = 10
//        seeMistsView.layer.cornerCurve = .continuous
//        updateKeywordsView.layer.cornerRadius = 10
//        updateKeywordsView.layer.cornerCurve = .continuous
//        seeMistsView.subviews.forEach { view in
//            view.layer.shadowOpacity = 0
//        }
//        updateKeywordsView.subviews.forEach { view in
//            view.layer.shadowOpacity = 0
//        }
//        updateKeywordCount(to: UserService.singleton.getKeywords().count)
//    }
//    
//    func setupGestureRecognizers() {
//        let keywordsTap = UITapGestureRecognizer(target: self, action: #selector(didPressKeywordsButton))
//        updateKeywordsView.addGestureRecognizer(keywordsTap)
//        let mistsTap = UITapGestureRecognizer(target: self, action: #selector(didPressMistboxButton))
//        seeMistsView.addGestureRecognizer(mistsTap)
//        let graphicTap = UITapGestureRecognizer(target: self, action: #selector(didPressUnopenedMistbox))
//        graphicImageView.addGestureRecognizer(graphicTap)
//    }
//    
//    func setupNavBar() {
//        navigationController?.isNavigationBarHidden = true
//        view.addSubview(customNavBar)
//        customNavBar.configure(title: "mistbox", leftItems: [.title], rightItems: [.profile], delegate: self)
//    }
//    
//    //MARK: - Countdown
//    
//    func setupCountdownTimer() {
//        Task {
//            while true {
//                DispatchQueue.main.async {
//                    self.updateUI()
//                }
//                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
//            }
//        }
//    }
//        
//    @MainActor
//    func updateUI() {
//        MistboxManager.shared.updateMistboxReleaseDates() //just to make sure we have the right time precisely before updating the UI
////        print("1")
//        switch currentLayout {
//        case .countdown:
//            print("2")
//            if !MistboxManager.shared.hasUserActivatedMistbox {
//                print("3")
//                setupWelcomeLayout()
//            } else if MistboxManager.shared.hasUnopenedMistbox {
//                print("4")
//                setupUnopenedLayout()
//            } else {
//                print("5")
//                updateProgressBarAndCountdownLabel()
//            }
//        case .welcome:
////            print("6")
//            if MistboxManager.shared.hasUserActivatedMistbox {
//                print("7")
//                setupCountdownLayout()
//                updateProgressBarAndCountdownLabel()
//            }
//        case .unopened:
//            print("8")
//            if !MistboxManager.shared.hasUnopenedMistbox {
//                print("9")
//                setupCountdownLayout()
//                updateProgressBarAndCountdownLabel()
//            }
//        }
//    }
//    
//    func updateProgressBarAndCountdownLabel() {
//        let timeUntilMistbox = MistboxManager.shared.timeUntilNextMistbox
//        if timeUntilMistbox.hours > 0 {
//            countdownWordLabel.text = "hours"
//            countdownNumberLabel.text = String(timeUntilMistbox.hours)
//        } else if timeUntilMistbox.minutes > 0 {
//            countdownWordLabel.text = "minutes"
//            countdownNumberLabel.text = String(timeUntilMistbox.minutes)
//        } else if timeUntilMistbox.seconds > 0 {
//            countdownWordLabel.text = "seconds"
//            countdownNumberLabel.text = String(timeUntilMistbox.seconds)
//        }
//        
//        if !isProgressViewAnimating {
//            circularProgressView.progress = MistboxManager.shared.percentUntilNextMistbox
//        }
//    }
//    
//    func updateKeywordCount(to newKeywordCount: Int) {
//        keywordsLabel.text = "keywords: " + String(newKeywordCount) + "/5"
//    }
//    
//    //MARK: - Layouts
//        
//    func setupWelcomeLayout() {
//        currentLayout = .welcome
//        
//        circularProgressView.isHidden = true
//        updateKeywordsView.isHidden = true
//        mistboxHeaderLabel.isHidden = true
//        learnMoreButton.setTitle("what's a mistbox?", for: .normal)
//        learnMoreButton.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
//        graphicImageView.isUserInteractionEnabled = false
//        graphicImageView.isHidden = false
//        graphicImageView.image = UIImage(named: "mistbox-graphic-nowords-1")!
//        seeMistsView.isHidden = false
//        seeMistsView.backgroundColor = .white
//        openIcon.tintColor = .lightGray
//        mistboxCountLabel.textColor = Constants.Color.mistBlack
//        mistboxHeaderLabel.textColor =  Constants.Color.mistBlack
//        
//        mistboxCountLabel.text = "setup your keywords to start receiving a daily mistbox"
//    }
//    
//    func setupCountdownLayout() {
//        currentLayout = .countdown
//        
//        circularProgressView.isHidden = false
//        seeMistsView.isHidden = false
//        updateKeywordsView.isHidden = false
//        mistboxHeaderLabel.isHidden = false
//        learnMoreButton.setTitle("until your new mistbox", for: .normal)
//        learnMoreButton.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
//        graphicImageView.isHidden = true
//        graphicImageView.isUserInteractionEnabled = false
//        seeMistsView.backgroundColor = .white
//        openIcon.tintColor = .lightGray
//        mistboxCountLabel.textColor = Constants.Color.mistBlack
//        mistboxHeaderLabel.textColor =  Constants.Color.mistBlack
//        
//        mistboxHeaderLabel.text = MistboxManager.shared.currentMistboxDateFormatted
//        mistboxCountLabel.text = String(MistboxManager.shared.getMostRecentMistboxPosts().count) + " mists"
//    }
//    
//    func setupUnopenedLayout() {
//        currentLayout = .unopened
//        
//        circularProgressView.isHidden = true
//        seeMistsView.isHidden = true
//        updateKeywordsView.isHidden = true
//        mistboxHeaderLabel.isHidden = false
//        graphicImageView.isHidden = false
//        graphicImageView.isUserInteractionEnabled = true
//        graphicImageView.image = UIImage(named: "mistbox")!
//        learnMoreButton.setTitle("tap to open", for: .normal)
//        learnMoreButton.setImage(nil, for: .normal)
//        updateKeywordsView.isHidden = true
//        
//        mistboxHeaderLabel.text = MistboxManager.shared.currentMistboxDateFormatted
//        mistboxCountLabel.text = String(MistboxManager.shared.getMostRecentMistboxPosts().count) + " unopened mists"
//        
//        shakeMistbox()
//    }
//    
//    func shakeMistbox() {
//        let duration = Double.random(in: 1.7..<3)
//        graphicImageView.animation = "shake"
//        graphicImageView.duration = duration
//        graphicImageView.curve = "spring"
//        graphicImageView.animate()
//        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
//            self.shakeMistbox()
//        }
//
//    }
//    
//    //MARK: - UserInteraction
//    
//    @objc func didPressMistboxButton() {
//        switch currentLayout {
//        case .countdown:
//            guard let mistboxExplore = CustomExploreParentViewController.create(setting: .mistbox) else { return }
//            navigationController?.pushViewController(mistboxExplore, animated: true)
//            MistboxManager.shared.openMistbox()
//        case .welcome:
//            didPressKeywordsButton() //because the MistboxButton acts as the KeywordsButton
//        case .unopened:
//            break //this wont be reached
//        }
//    }
//    
//    @IBAction func didPressLearnMoreButton(_ sender: UIButton) {
//        switch currentLayout {
//        case .countdown, .welcome:
//            let learnMoreVC = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil).instantiateViewController(withIdentifier: Constants.SBID.VC.WhatIsMistbox)
//            present(learnMoreVC, animated: true)
//        case .unopened:
//            break
//        }
//    }
//    
//    @objc func didPressUnopenedMistbox() {
//        guard let mistboxExplore = CustomExploreParentViewController.create(setting: .mistbox) else { return }
//
//        customNavBar.isHidden = true
//        learnMoreButton.alpha = 0
//        tabBarController?.tabBar.isHidden = true
//        
//        graphicImageView.animation = "zoomOut"
//        graphicImageView.duration = 4
//        graphicImageView.curve = "linear"
//        graphicImageView.scaleX = 5
//        graphicImageView.scaleY = 5
//        graphicImageView.animate()
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in //so that the navbar turns hidden before the animation is added, otherwise navbar disappear also is aniamted
//            let transition: CATransition = CATransition()
//            transition.duration = 4
//            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
//            transition.type = CATransitionType.fade
//            navigationController!.view.layer.add(transition, forKey: nil)
//            navigationController?.pushViewController(mistboxExplore, animated: false) {
//                self.customNavBar.isHidden = false
//                self.learnMoreButton.alpha = 1
//                //settings tabbar.ishidden = true sets it visible too early
//                MistboxManager.shared.openMistbox()
//            }
//        }
//    }
//    
//    @objc func didPressKeywordsButton() {
//        switch currentLayout {
//        case .countdown:
//            sendToKeywordsVC()
//        case .welcome:
//            askForPermissionsAndSendToKeywordsVC()
//        case .unopened:
//            break //keywords button should be hidden while in .unopened
//        }
//    }
//    
//    func askForPermissionsAndSendToKeywordsVC() {
//        let center  = UNUserNotificationCenter.current()
////        center.delegate = self
//        center.getNotificationSettings(completionHandler: { [self] (settings) in
//            switch settings.authorizationStatus {
//            case .authorized:
//                sendToKeywordsVC()
//            case .denied, .notDetermined:
//                CustomSwiftMessages.showPermissionRequest(permissionType: .mistboxNotifications) { approved in
//                    guard approved else { return }
//                    if settings.authorizationStatus == .denied {
//                        CustomSwiftMessages.showSettingsAlertController(title: "enable notifications in settings", message: "", on: self)
//                    } else {
//                        center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
//                            guard granted else { return }
//                            UIApplication.shared.registerForRemoteNotifications()
//                            self.sendToKeywordsVC()
//                        }
//                    }
//                }
//            default:
//                break //when will this occur?? idk
//            }
//        })
//    }
//    
//    func sendToKeywordsVC() {
//        DispatchQueue.main.async {
//            let keywordsVC = EnterKeywordsViewController.create { newKeywordCount in
//                self.updateKeywordCount(to: newKeywordCount)
//            }
//            self.navigationController?.pushViewController(keywordsVC, animated: true)
//        }
//    }
//
//}
//
//extension OldMistboxViewController: CustomNavBarDelegate { //nothing additional needed here
//    
//}
