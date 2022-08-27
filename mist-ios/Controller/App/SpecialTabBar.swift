//
//  CustomTabBar.swift
//  CustomTabBar
//
//  Created by Adam Novak on 2022-06-07.
//

import UIKit

class SpecialTabBar: UITabBar {
        
    public lazy var middleButton: UIButton! = {
        let middleButton = UIButton(configuration: UIButton.Configuration.plain())
        middleButton.setImage(UIImage(named: "submitbutton")!, for: .normal)
        middleButton.translatesAutoresizingMaskIntoConstraints = false
        middleButton.isUserInteractionEnabled = true
//        middleButton.frame = .init(x: 0, y: 0, width: 40, height: 40)
//        middleButton.contentHorizontalAlignment = .fill
//        middleButton.contentVerticalAlignment = .fill
//        middleButton.imageView?.contentMode = .scaleAspectFit
        middleButton.addTarget(self, action: #selector(middleButtonAction), for: .touchUpInside)
        
        
//        middleButton.setBackgroundImage(UIImage(named: "submitbutton"), for: .normal)
//        middleButton.layoutIfNeeded()
//        middleButton.subviews.first?.contentMode = .scaleAspectFit
//        middleButton.subviews.forEach { view in
//            if let button = view as? UIImageView {
//                button.contentMode = .scaleAspectFit
//            }
//        }
        
        
        addSubview(middleButton)
        return middleButton
    }()
    
    // MARK: - View Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        addMiddleButton()
        // Badge color acts as the flag for communicating with UITabBarDelegate
        // Nil is the default
        // Non-nil indicates that the middle button was pressed
        // middleButton will never have badges, so this is safe to use as a flag
        items![1].badgeColor = nil
    }
    
    func addMiddleButton() {
        NSLayoutConstraint.activate([
            middleButton.topAnchor.constraint(equalTo: self.topAnchor, constant: -40),
            middleButton.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
        ])
    }
    
    // MARK: - Actions
    
    @objc func middleButtonAction(sender: UIButton) {
        items![1].badgeColor = .clear
        delegate?.tabBar?(self, didSelect: items![1])
        items![1].badgeColor = nil
    }
    
    // MARK: - HitTest
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !clipsToBounds && !isHidden && alpha > 0 else { return nil }
        return self.middleButton.frame.contains(point) ? self.middleButton : super.hitTest(point, with: event)
    }
}
