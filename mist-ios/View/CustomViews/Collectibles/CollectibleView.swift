//
//  CollectibleView.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/24/22.
//

import Foundation

protocol CollectibleDelegate {
    
}

class CollectibleView: UIView {
        
    //MARK: - Properties
    
    //UI
    @IBOutlet weak var firstCollectibleBackgroundView: UIView!
    @IBOutlet weak var firstCollectibleTitleLabel: UILabel!
    @IBOutlet weak var firstCollectibleImageView: UIView!
    
    var collectibleType: Int!
    var delegate: CollectibleDelegate!
        
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
        guard let contentView = loadViewFromNib(nibName: "EnvelopeView") else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        envelopeImageView.applyMediumShadow()
        titleShadowView.applyMediumShadow()
        titleMaskingView.clipsToBounds = true
        skipButton.setImage(UIImage(systemName: "bin.xmark"), for: .normal) //to avoid name deprecation warning
    }
    
    
    func setupButtons() {
        openButton.roundCornersViaCornerRadius(radius: 8)
        openButton.clipsToBounds = true
        openButtonShadowSuperView.applyMediumShadow()
        skipButton.roundCornersViaCornerRadius(radius: 5)
        skipButton.clipsToBounds = true
        
        if #available(iOS 14, *) {
            skipButton.setImage(UIImage(systemName: "xmark.bin"), for: .normal)
        }
        else {
            skipButton.setImage(UIImage(systemName: "bin.xmark"), for: .normal)
        }
        skipButton.applyMediumShadow()
        openButton.setBackgroundColor(Constants.Color.mistPurple, for: .normal)
        openButton.setBackgroundColor(Constants.Color.mistLilac, for: .highlighted)
    }
        
    //MARK: - User Interaction
    
    @objc func collectibleDidTapped() {
        
    }
    
}

//MARK: - Public Interface

extension CollectibleView {
    
    // Note: the constraints for the PostView should already be set-up when this is called.
    // Otherwise you'll get loads of constraint errors in the console
    func configureForCollectible(collectibleType: Int, delegate: CollectibleDelegate) {
        self.collectibleType = collectibleType
        self.delegate = delegate
    }
    
}
