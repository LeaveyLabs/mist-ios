//
//  MistWideLogoView.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import Foundation

@IBDesignable class MistWideLogoView: UIView {
    
    enum LogoColor {
        case white, pink
    }
            
    //UI
    @IBOutlet weak var heartImageView: SpringImageView!
    @IBOutlet weak var mistLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
        
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
        guard let contentView = loadViewFromNib(nibName: "MistWideLogoView") else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
    }
    
    func setup(color: LogoColor) {
        switch color {
        case .white:
            heartImageView.image = UIImage(named: "mist-white-heart")
            mistLabel.textColor = .white
            subtitleLabel.textColor = .white
        case .pink:
            heartImageView.image = UIImage(named: "mist-pink-heart")
            mistLabel.textColor = mistUIColor()
            subtitleLabel.textColor = mistUIColor()
        }
    }
    
    // This function has the heart fly far off the screen (3000px above) with a longer duration
    // which makes the .curveEaseIn animation look a little better. Plus, we can be confident
    // the heart will have flown off the screen by then
    func flyHeartUp() {
        let yDif: CGFloat = 3000
        let yPosition = heartImageView.frame.origin.y - yDif

        let xPosition = heartImageView.frame.origin.x
        let width = heartImageView.frame.size.width
        let height = heartImageView.frame.size.height
        
        UIView.animate(withDuration: 4,
                       delay: 0,
                       options: .curveEaseIn) {
            self.heartImageView.frame = CGRect(x: xPosition,
                                               y: yPosition,
                                               width: width,
                                               height: height)
        }
    }
    
}
