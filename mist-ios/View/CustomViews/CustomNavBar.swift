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
}

enum CustomNavBarItem: CaseIterable {
    case profile, search, title, map
}

class CustomNavBar: UIView {
    
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
        guard let contentView = loadViewFromNib(nibName: "CustomNavBar") else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        
//        self.applyLightBottomOnlyShadow()
        contentView.applyLightBottomOnlyShadow()
    }
    
    func setupItem(_ item: CustomNavBarItem, on stackView: UIStackView, withTitle title: String) {
        switch item {
        case .search:
            break
        case .profile:
            accountButton = UIButton(type: .custom)
            guard let accountButton = accountButton else { return }
            accountButton.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
            accountButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
            accountButton.imageView?.becomeProfilePicImageView(with: UserService.singleton.getProfilePic())
            accountButton.addAction(.init(handler: { action in
                self.delegate.handleProfileButtonTap()
            }), for: .touchUpInside)
            stackView.addArrangedSubview(accountButton)
        case .title:
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = UIFont(name: Constants.Font.Heavy, size: 30)
            titleLabel.textColor = Constants.Color.mistBlack
            stackView.addArrangedSubview(titleLabel)
        case .map:
            let button = UIButton()
            button.imageView?.image = UIImage(named: "toggle-map-button")
            button.tintColor = Constants.Color.mistBlack
            button.addAction(.init(handler: { action in
                self.delegate.handleMapButtonTap()
            }), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
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
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: superview.safeTopAnchor),
            self.widthAnchor.constraint(equalTo: superview.widthAnchor),
            self.heightAnchor.constraint(equalToConstant: height),
            self.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
        ])
        superview.bringSubviewToFront(self)
        
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
