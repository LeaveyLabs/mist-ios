//
//  CustomTabBar.swift
//  CustomTabBar
//
//  Created by Adam Novak on 2022-06-07.
//

import UIKit

class SpecialTabBar: UITabBar {
    
    public lazy var middleButton: SpringButton! = {
        let middleButton = SpringButton()
        middleButton.adjustsImageWhenDisabled = false
        middleButton.adjustsImageWhenHighlighted = false
        middleButton.setImage(UIImage(named: "submitbutton")!, for: .normal)
        middleButton.translatesAutoresizingMaskIntoConstraints = false
        middleButton.isUserInteractionEnabled = true
        middleButton.contentHorizontalAlignment = .fill
        middleButton.contentVerticalAlignment = .fill
        middleButton.imageView?.contentMode = .scaleAspectFit
        middleButton.addTarget(self, action: #selector(middleButtonAction), for: .touchUpInside)
        addSubview(middleButton)
        return middleButton
    }()
    
    func buttonRock() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [self] in
            middleButton.animation = "swing"
            middleButton.duration = 7
            middleButton.animate()
            self.buttonRock()
        }
    }
    
    // MARK: - View Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        addMiddleButton()
        buttonRock()
    }
    
    var SubmitButtonHeight: Double {
        return self.bounds.width * 0.225
    }

    func addMiddleButton() {
        NSLayoutConstraint.activate([
            middleButton.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.225),
            middleButton.heightAnchor.constraint(equalTo: middleButton.widthAnchor),
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
