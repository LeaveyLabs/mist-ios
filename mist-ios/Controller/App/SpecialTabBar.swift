//
//  CustomTabBar.swift
//  CustomTabBar
//
//  Created by Adam Novak on 2022-06-07.
//

import UIKit

class SpecialTabBar: UITabBar {

    public lazy var middleButton: UIButton! = {
        let middleButton = SpringButton(configuration: UIButton.Configuration.plain())
        middleButton.setImage(UIImage(named: "submitbutton")!, for: .normal)
        middleButton.translatesAutoresizingMaskIntoConstraints = false
        middleButton.isUserInteractionEnabled = true
//        middleButton.frame = .init(x: 0, y: 0, width: 40, height: 40)
//        middleButton.contentHorizontalAlignment = .fill
//        middleButton.contentVerticalAlignment = .fill
//        middleButton.imageView?.contentMode = .scaleAspectFit
        middleButton.addTarget(self, action: #selector(middleButtonAction), for: .touchUpInside)
        addSubview(middleButton)
                
        middleButton.animation = "swing"
        middleButton.duration = 7
        middleButton.repeatCount = 30
        middleButton.animate()
        return middleButton
        
    }()
    
    // MARK: - View Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        addMiddleButton()
    }

    func addMiddleButton() {
        NSLayoutConstraint.activate([
            middleButton.widthAnchor.constraint(equalToConstant: 75),
            middleButton.heightAnchor.constraint(equalToConstant: 75),
            middleButton.bottomAnchor.constraint(equalTo: self.topAnchor, constant: -15),
            middleButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -15),
        ])
    }

    // MARK: - Actions

    @objc func middleButtonAction(sender: UIButton) {
        guard let tabBarItem = self.items?.first else { return }
        delegate?.tabBar?(self, didEndCustomizing: [tabBarItem], changed: false)
    }

    // MARK: - HitTest

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !clipsToBounds && !isHidden && alpha > 0 else { return nil }
        return self.middleButton.frame.contains(point) ? self.middleButton : super.hitTest(point, with: event)
    }
}
