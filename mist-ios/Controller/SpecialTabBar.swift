//
//  CustomTabBar.swift
//  CustomTabBar
//
//  Created by Keihan Kamangar on 2021-06-07.
//

import UIKit

class SpecialTabBar: UITabBar {
    
    // MARK: - Variables
    public var didTapButton: (() -> ())?
    
    public lazy var middleButton: UIButton! = {
        middleButton = UIButton()
        middleButton.adjustsImageWhenHighlighted = false //deprecated, but only for the new "UIButtonConfiguration" buttons, which we're not using here
//        centerButton.frame = CGRect(x: 0.0, y: 0.0, width: buttonImage.size.width, height: buttonImage.size.height)
        middleButton.frame.size = CGSize(width: 48, height: 48)
        middleButton.translatesAutoresizingMaskIntoConstraints = false
        middleButton.setImage(UIImage(named: "submitbutton")!, for: .normal)
        middleButton.isUserInteractionEnabled = true
        middleButton.addTarget(self, action: #selector(middleButtonAction), for: .touchUpInside)
        middleButton.frame.size = CGSize(width: 48, height: 48)
        
        addSubview(middleButton)
        
        return middleButton
    }()
    
    // MARK: - View Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        addMiddleButton()
    }
    
    func addMiddleButton() {
        self.layer.shadowColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1).cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.layer.shadowRadius = 4.0
        self.layer.shadowOpacity = 0.4
        self.layer.masksToBounds = false
        
        NSLayoutConstraint.activate([
            middleButton.topAnchor.constraint(equalTo: self.topAnchor, constant: -30),
            middleButton.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
        ])
        
  }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: - Actions
    @objc func middleButtonAction(sender: UIButton) {
        didTapButton?()
    }
    
    // MARK: - HitTest
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !clipsToBounds && !isHidden && alpha > 0 else { return nil }
        
        return self.middleButton.frame.contains(point) ? self.middleButton : super.hitTest(point, with: event)
    }
}
