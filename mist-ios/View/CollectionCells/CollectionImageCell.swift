//
//  CollectionImageCell.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/28/22.
//

import Foundation

class CollectionImageCell: UICollectionViewCell {
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
                
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.7),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
        ])
    }
    
    func setup(image: UIImage) {
        imageView.image = image
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
