//
//  CollectibleView.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/24/22.
//

import Foundation

protocol CollectibleViewDelegate {
    func collectibleDidTapped(type: Int)
}

class CollectibleView: UIView {
        
    //MARK: - Properties
    
    //UI
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var collectibleType: Int!
    var delegate: CollectibleViewDelegate!
        
    static let boldAttributes: [NSAttributedString.Key : Any] = [
        .font: UIFont(name: Constants.Font.Heavy, size: 18)!,
        .foregroundColor: UIColor.white,
    ]
    static let normalAttributes: [NSAttributedString.Key : Any] = [
        .font: UIFont(name: Constants.Font.Roman, size: 18)!,
        .foregroundColor: UIColor.white,
    ]
    
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
        guard let contentView = loadViewFromNib(nibName: "CollectibleView") else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        
        backgroundView.applyLightMediumShadow()
        backgroundView.roundCornersViaCornerRadius(radius: 13)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(collectibleDidTapped))
        self.addGestureRecognizer(tapGesture)
    }
        
    //MARK: - User Interaction
    
    @objc func collectibleDidTapped() {
        delegate.collectibleDidTapped(type: collectibleType)
    }
    
}

//MARK: - Public Interface

extension CollectibleView {
    
    // Note: the constraints for the PostView should already be set-up when this is called.
    // Otherwise you'll get loads of constraint errors in the console
    func configureForCollectible(collectibleType: Int, delegate: CollectibleViewDelegate) {
        self.collectibleType = collectibleType
        self.delegate = delegate
        let collectible = Collectible(type: collectibleType)
        imageView.image = collectible.image
        titleLabel.text = collectible.title
    }
    
}
