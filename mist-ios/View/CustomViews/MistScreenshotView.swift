//
//  MistScreenshotView.swift
//  mist-ios
//
//  Created by Adam Monterey on 10/11/22.
//

import Foundation

class MistScreenshotVIew: UIView {
        
    //MARK: - Properties
    
    //UI
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var postView: PostView!
    @IBOutlet weak var pinImageView: UIImageView!
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var bottomLogo: UIImageView!
    
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
        guard let contentView = loadViewFromNib(nibName: "MistScreenshotView") else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        pinImageView.applyLightMediumShadow()
    }
    
}

//MARK: - Public Interface

extension MistScreenshotVIew {
    
    // Note: the constraints for the PostView should already be set-up when this is called.
    // Otherwise you'll get loads of constraint errors in the console
    func configure(post: Post, postDelegate: PostDelegate) {
        postView.configurePost(post: post, delegate: postDelegate, arrowPosition: .bottom)
        emojiLabel.text = post.topEmoji
        postView.backgroundColor = Constants.Color.mistLilac //TODO: we can't use gradient for now, because for some reason, even though the background color is clear, there's some color behind the postView
    }

}
