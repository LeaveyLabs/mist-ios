//
//  CustomNavBar.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/23/22.
//

import Foundation

protocol CustomNavBarDelegate {
    func handleProfileButtonTap()
    func handleMapButtonTap()
    func handleSearchButtonTap()
    func handleXMarkButtonTap()
    func handleBackButtonTap()
}

extension CustomNavBarDelegate where Self: UIViewController {
    func handleProfileButtonTap() {
        guard
            let myAccountNavigation = storyboard?.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation) as? UINavigationController,
            let myAccountVC = myAccountNavigation.topViewController as? MyAccountViewController
        else { return }
        myAccountNavigation.modalPresentationStyle = .fullScreen
        myAccountVC.rerenderProfileCallback = { } //no longer needed, since we update the accountButton on moveToSuperview
        self.navigationController?.present(myAccountNavigation, animated: true, completion: nil)
    }
    
    func handleMapButtonTap() {
        fatalError("Sublcass must override this method")
    }
    
    func handleSearchButtonTap() {
        fatalError("Sublcass must override this method")
    }
    
    func handleXMarkButtonTap() {
        fatalError("Sublcass must override this method")
    }
    
    func handleBackButtonTap() {
        dismiss(animated: true)
    }
}

class CustomNavBar: UIView {
    
    static let navBarButtonConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)
    
    enum CustomNavBarItem: CaseIterable {
        case profile, search, title, map, back, xmark

        var image: UIImage {
            switch self {
            case .profile:
                return UserService.singleton.getProfilePic()
            case .search:
                return UIImage(systemName: "magnifyingglass", withConfiguration: navBarButtonConfig)!
            case .title:
                return UIImage()
            case .map:
                return UIImage(named: "toggle-map-button")!
            case .back:
                return UIImage(systemName: "chevron.backward", withConfiguration: navBarButtonConfig)!
            case .xmark:
                return UIImage(systemName: "xmark", withConfiguration: navBarButtonConfig)!
            }
        }
    }
    
    //MARK: - Properties
        
    //UI
    @IBOutlet weak var leftStackView: UIStackView!
    @IBOutlet weak var rightStackView: UIStackView!
    
    var delegate: CustomNavBarDelegate!
    
    var accountButton: UIButton?
            
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
            stackView.addArrangedSubview(titleLabel)
        case .map:
            stackView.addArrangedSubview(navBarButton(for: .map))
        case .back:
            let asdf = navBarButton(for: .back)
            stackView.addArrangedSubview(asdf)
        case .xmark:
            stackView.addArrangedSubview(navBarButton(for: .xmark))
        }
    }
    
    private func navBarButton(for item: CustomNavBarItem) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(item.image, for: .normal)
        button.tintColor = Constants.Color.mistBlack
        let buttonWidth = item == .profile ? 35 : 20
        button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonWidth)
        button.widthAnchor.constraint(equalToConstant: button.frame.width).isActive = true
        
        switch item {
        case .profile:
            button.addAction(.init(handler: { action in
                self.delegate.handleProfileButtonTap()
            }), for: .touchUpInside)
        case .search:
            button.addAction(.init(handler: { action in
                self.delegate.handleSearchButtonTap()
            }), for: .touchUpInside)
        case .title:
            break
        case .map:
            button.addAction(.init(handler: { action in
                self.delegate.handleMapButtonTap()
            }), for: .touchUpInside)
        case .back:
            button.addAction(.init(handler: { action in
                self.delegate.handleBackButtonTap()
            }), for: .touchUpInside)
        case .xmark:
            button.addAction(.init(handler: { action in
                self.delegate.handleXMarkButtonTap()
            }), for: .touchUpInside)
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
            setupItem(item, on: leftStackView, withTitle: title)
        }
        leftStackView.addArrangedSubview(UIView())
        rightStackView.addArrangedSubview(UIView())
        rightItems.forEach { item in
            setupItem(item, on: rightStackView, withTitle: title)
        }
    }
    
}
