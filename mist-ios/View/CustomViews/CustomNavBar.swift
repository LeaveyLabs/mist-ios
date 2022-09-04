//
//  CustomNavBar.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/23/22.
//

import Foundation

protocol CustomNavBarDelegate {
    func handleProfileButtonTap()
    
    func handleFilterButtonTap()
    func handleMapFeedToggleButtonTap()
    func handleSearchButtonTap()
    
    func handleCloseButtonTap()
    func handleBackButtonTap()
}

extension CustomNavBar {
    
    //MARK: - User Interaction layer between delegate... because objective c probs...
    
    @objc func handleProfileButtonTap() {
        delegate.handleProfileButtonTap()
    }
    
    @objc func handleFilterButtonTap() {
        delegate.handleFilterButtonTap()
    }
    
    @objc func handleMapFeedToggleButtonTap() {
        delegate.handleMapFeedToggleButtonTap()
    }
    
    @objc func handleSearchButtonTap() {
        delegate.handleSearchButtonTap()
    }
    
    @objc func handleBackButtonTap() {
        delegate.handleBackButtonTap()
    }
    
    @objc func handleCloseButtonTap() {
        delegate.handleCloseButtonTap()
    }
    
}

class CustomNavBar: UIView {
        
    enum CustomNavBarItem: CaseIterable {
        case title, profile, search, filter, mapFeedToggle, back, close

        var image: UIImage {
            switch self {
            case .profile:
                return UserService.singleton.getProfilePic()
            case .search:
                return UIImage(systemName: "magnifyingglass")!.withConfiguration(UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default))
            case .title:
                return UIImage()
            case .filter:
                return UIImage()
            case .mapFeedToggle:
                return UIImage()
            case .back:
                return UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default))!
            case .close:
                return UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default))!
            }
        }
    }
    
    //MARK: - Properties
        
    //UI
    @IBOutlet weak var stackView: UIStackView!
    
    var delegate: CustomNavBarDelegate!
    
    var accountButton: UIButton?
    var searchFilterButton: UIButton?
    
    let TOGGLE_MAP_IMAGE = UIImage(named: "toggle-map-button")!
    let TOGGLE_FEED_IMAGE = UIImage(named: "toggle-feed-button")!
    let FILTER_IMAGE = UIImage() //UIImage(named: "filter-button")

    //MARK: - Constructors
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customInit()
    }
    
    private func customInit() {
        nibInit()
        applyLightBottomOnlyShadow()
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 15
    }
    
    private func nibInit() {
        guard let contentView = loadViewFromNib(nibName: String(describing: CustomNavBar.self)) else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
    }
    
    private func setupItem(_ item: CustomNavBarItem, on stackView: UIStackView, withTitle title: String) {
        switch item {
        case .search:
            stackView.addArrangedSubview(navBarButton(for: .search))
        case .filter:
            stackView.addArrangedSubview(navBarButton(for: .search))
        case .profile:
            accountButton = navBarButton(for: .profile)
            guard let accountButton = accountButton else { return }
            accountButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
            stackView.addArrangedSubview(accountButton)
        case .title:
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = UIFont(name: Constants.Font.Heavy, size: 28)
            titleLabel.textColor = Constants.Color.mistBlack
            titleLabel.sizeToFit()
            stackView.addArrangedSubview(titleLabel)
        case .mapFeedToggle:
            stackView.addArrangedSubview(navBarButton(for: .mapFeedToggle))
        case .back:
            stackView.addArrangedSubview(navBarButton(for: .back))
        case .close:
            stackView.addArrangedSubview(navBarButton(for: .close))
        }
    }
    
    private func navBarButton(for item: CustomNavBarItem) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(item.image, for: .normal)
        button.tintColor = Constants.Color.mistBlack
        
        let buttonWidth: CGFloat
        switch item {
        case .title:
            return button //the title doesnt get a button as of now. it's width is calculated automatically
        case .profile:
            buttonWidth = 35
        case .search, .filter, .mapFeedToggle:
            buttonWidth = 30
        case .back, .close:
            buttonWidth = 20
        }
        button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonWidth)
        button.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        button.heightAnchor.constraint(equalToConstant: buttonWidth).isActive = true

        switch item {
        case .profile:
            button.addTarget(self, action: #selector(handleProfileButtonTap), for: .touchUpInside)
        case .search:
            button.addTarget(self, action: #selector(handleSearchButtonTap), for: .touchUpInside)
        case .filter:
            button.addTarget(self, action: #selector(handleFilterButtonTap), for: .touchUpInside)
        case .title:
            break
        case .mapFeedToggle:
            break
//            button.addAction(.init(handler: { [self] action in
//                if button.image(for: .normal) == TOGGLE_MAP_IMAGE {
//                    button.setImage(TOGGLE_FEED_IMAGE, for: .normal)
//                    searchFilterButton?.setImage(SEARCH_IMAGE, for: .normal)
//                } else {
//                    button.setImage(TOGGLE_MAP_IMAGE, for: .normal)
//                    searchFilterButton?.setImage(FILTER_IMAGE, for: .normal)
//                }
//                delegate.handleMapFeedToggleButtonTap()
//            }), for: .touchUpInside)
        case .back:
            button.addTarget(self, action: #selector(handleBackButtonTap), for: .touchUpInside)
        case .close:
            button.addTarget(self, action: #selector(handleCloseButtonTap), for: .touchUpInside)
        }
        return button
    }
    
    private func setupConstraints(with superview: UIView, height: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: superview.safeTopAnchor),
            self.widthAnchor.constraint(equalTo: superview.widthAnchor),
            self.heightAnchor.constraint(equalToConstant: height),
            self.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
        ])
        superview.bringSubviewToFront(self)
    }
    
    //MARK: - Lifecycle
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        accountButton?.setImage(UserService.singleton.getProfilePic(), for: .normal)
    }
    
}

//MARK: - Public Interface

extension CustomNavBar {
    
    // Note: the constraints for the PostView should already be set-up when this is called.
    // Otherwise you'll get loads of constraint errors in the console
    func configure(title: String, leftItems: [CustomNavBarItem], rightItems: [CustomNavBarItem], delegate: CustomNavBarDelegate, height: CGFloat = 55.0) {
        guard let superview = superview else {
            print("custom nav bar must be added to superview before being configured")
            return
        }
        setupConstraints(with: superview, height: height)
        self.delegate = delegate
        
        leftItems.forEach { item in
            setupItem(item, on: stackView, withTitle: title)
        }
        stackView.addArrangedSubview(UIView())
        rightItems.forEach { item in
            setupItem(item, on: stackView, withTitle: title)
        }
    }
    
}
