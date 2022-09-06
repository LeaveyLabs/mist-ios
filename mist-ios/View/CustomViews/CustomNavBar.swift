//
//  CustomNavBar.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/23/22.
//

import Foundation

extension UIViewController {
    
    @objc func handleProfileButtonTap() {
        guard
            let myAccountNavigation = storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation) as? UINavigationController,
            let myAccountVC = myAccountNavigation.topViewController as? MyAccountViewController
        else { return }
        myAccountNavigation.modalPresentationStyle = .fullScreen
        myAccountVC.rerenderProfileCallback = { } //no longer needed, since we update the accountButton on moveToSuperview
        self.navigationController?.present(myAccountNavigation, animated: true, completion: nil)
    }
    
}

class CustomNavBar: UIView {

    enum CustomNavBarItem: CaseIterable {
        case title, profile, search, filter, mapFeedToggle, back, close, favorite, save

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
            case .favorite:
                return UIImage(systemName: "bookmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium, scale: .default))!
            case .save:
                return UIImage()
            }
        }
        
        var selectedImage: UIImage {
            switch self {
            case .title:
                return UIImage()
            case .profile:
                return UIImage()
            case .search:
                return UIImage()
            case .filter:
                return UIImage()
            case .mapFeedToggle:
                return UIImage()
            case .back:
                return UIImage()
            case .close:
                return UIImage()
            case .favorite:
                return UIImage(systemName: "bookmark.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium, scale: .default))!
            case .save:
                return UIImage()
            }
        }
    }
    
    //MARK: - Properties
        
    //UI
    @IBOutlet weak var stackView: UIStackView!
        
    var accountButton = CustomNavBar.navBarButton(for: .profile)
    lazy var accountBadgeHub = BadgeHub(view: accountButton) // Initially count set to 0

    var searchButton = CustomNavBar.navBarButton(for: .search)
    var titleLabel = UILabel()
    var filterButton = CustomNavBar.navBarButton(for: .filter)
    var mapFeedToggleButton = CustomNavBar.navBarButton(for: .mapFeedToggle)
    var backButton = CustomNavBar.navBarButton(for: .back)
    var closeButton = CustomNavBar.navBarButton(for: .close)
    var favoriteButton = CustomNavBar.navBarButton(for: .favorite)
    var saveButton = CustomNavBar.navBarButton(for: .save)
    
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
        setupStackView()
        setupSpecialItems()
    }
    
    func setupStackView() {
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
    
    func setupSpecialItems() {
        accountButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
        titleLabel.font = UIFont(name: Constants.Font.Heavy, size: 28)
        titleLabel.textColor = Constants.Color.mistBlack
        titleLabel.sizeToFit()
    }
        
    static private func navBarButton(for item: CustomNavBarItem) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(item.image, for: .normal)
        if item == .favorite {
            button.setImage(item.selectedImage, for: .selected)
        }
        if item == .save {
            button.setTitle("save", for: .normal)
            button.setTitle("save", for: .disabled)
            button.setTitleColor(Constants.Color.mistBlack, for: .normal)
            button.setTitleColor(.lightGray, for: .disabled)
            button.titleLabel?.font = UIFont(name: Constants.Font.Roman, size: 18)!
        }
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
        case .favorite:
            buttonWidth = 25
        case .save:
            buttonWidth = 50
        }
        button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonWidth)
        button.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        button.heightAnchor.constraint(equalToConstant: item == .save ? 30 : buttonWidth).isActive = true
        return button
    }
    
    //MARK: - Lifecycle
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        accountButton.setImage(UserService.singleton.getProfilePic(), for: .normal)
        accountBadgeHub.setCount(DeviceService.shared.unreadMentionsCount()) //TODO: not sure if this is needed bc we also call it in the vc's viewwillappear
    }
    
}

//MARK: - Public Interface

extension CustomNavBar {
    
    // Note: the constraints for the PostView should already be set-up when this is called.
    // Otherwise you'll get loads of constraint errors in the console
    func configure(title: String, leftItems: [CustomNavBarItem], rightItems: [CustomNavBarItem], height: CGFloat = 55.0) {
        guard let superview = superview else {
            print("custom nav bar must be added to superview before being configured")
            return
        }
        setupConstraints(with: superview, height: height)
        
        leftItems.forEach { item in
            configureItem(item, withTitle: title)
        }
        stackView.addArrangedSubview(UIView())
        rightItems.forEach { item in
            configureItem(item, withTitle: title)
        }
    }
    
    private func configureItem(_ item: CustomNavBarItem, withTitle title: String) {
        switch item {
        case .title:
            titleLabel.text = title
            stackView.addArrangedSubview(titleLabel)
        case .profile:
            stackView.addArrangedSubview(accountButton)
        case .search:
            stackView.addArrangedSubview(searchButton)
        case .filter:
            stackView.addArrangedSubview(filterButton)
        case .mapFeedToggle:
            stackView.addArrangedSubview(mapFeedToggleButton)
        case .back:
            stackView.addArrangedSubview(backButton)
        case .close:
            stackView.addArrangedSubview(closeButton)
        case .favorite:
            stackView.addArrangedSubview(favoriteButton)
        case .save:
            stackView.addArrangedSubview(saveButton)
        }
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
    
}
