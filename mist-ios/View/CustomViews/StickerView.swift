//
//  StickerView.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/25/22.
//

import Foundation

class StickerView: UIView {
        
    //MARK: - Properties
    
    //UI
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
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
        guard let contentView = loadViewFromNib(nibName: "StickerView") else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        
        backgroundView.applyLightMediumShadow()
//        backgroundView.roundCornersViaCornerRadius(radius: 10)
        backgroundView.roundCorners(corners: .allCorners, radius: 10)
    }
    
}

//MARK: - Public Interface

extension StickerView {
    
    // Note: the constraints for the PostView should already be set-up when this is called.
    // Otherwise you'll get loads of constraint errors in the console
    func configure(stickerType: StickerType, promptNumber: Int? = nil) {
        switch stickerType {
        case .connected:
            titleLabel.text = "connected"
            backgroundView.backgroundColor = Constants.Color.mistLilac
        case .prompt:
            guard promptNumber != nil else { return }
            titleLabel.text = "prompt #" + String(promptNumber!)
            backgroundView.backgroundColor = Constants.Color.mistLilacPurple
        }
    }

}

enum StickerType {
    case connected, prompt
}
