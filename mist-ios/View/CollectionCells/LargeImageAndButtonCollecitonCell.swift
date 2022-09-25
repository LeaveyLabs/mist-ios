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
    let closeButton = UIButton()
    var lastIndex: Int!

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
                
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.88),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.6),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
        ])
    }
    
    func setup(image: UIImage, delegate: LargeImageCollectionCellDelegate, index: Int, lastIndex: Int, continueButtonTitle: String) {
        setupCloseButton(continueButtonTitle: continueButtonTitle)
        imageView.image = image
        self.lastIndex = lastIndex
        self.guidelinesDelegate = delegate
        if lastIndex == index {
            closeButton.isHidden = false
        } else {
            closeButton.isHidden = true
        }
    }
    
    func setupCloseButton(continueButtonTitle: String) {
        let attributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: 20)!]
        closeButton.roundCornersViaCornerRadius(radius: 10)
        closeButton.clipsToBounds = true
        closeButton.setAttributedTitle(NSAttributedString(string: continueButtonTitle, attributes: attributes), for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = Constants.Color.mistLilac
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
