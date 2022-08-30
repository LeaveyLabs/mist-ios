//
//  GuidelinesCollecitonCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/28/22.
//

import Foundation

class LargeImageAndButtonCollectionCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    var guidelinesDelegate: LargeImageCollectionCellDelegate!
    var hasSetupCloseButton = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
                
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.6),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
        ])
    }
    
    func setup(image: UIImage, delegate: LargeImageCollectionCellDelegate, index: Int) {
        imageView.image = image
        self.guidelinesDelegate = delegate
        if index == 2 && !hasSetupCloseButton {
            setupCloseButton()
            hasSetupCloseButton = true
        }
    }
    
    func setupCloseButton() {
        
        
        let attributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: 20)!]
        var config = UIButton.Configuration.filled()
        config.attributedTitle = AttributedString("got it", attributes: AttributeContainer(attributes))
        config.background.backgroundColor = Constants.Color.mistLilac

        let closeButton = UIButton(configuration: config)
        closeButton.titleLabel?.textColor = .white
        closeButton.tintColor = Constants.Color.mistLilac
        closeButton.addTarget(self, action: #selector(closeButtonDidPressed), for: .touchUpInside)
        addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            closeButton.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            closeButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 60),
        ])
    }
    
    @objc func closeButtonDidPressed() {
        guidelinesDelegate.closeButtonPressed()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
