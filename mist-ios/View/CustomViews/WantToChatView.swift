//
//  WantToChatView.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/3/22.
//

import Foundation

protocol WantToChatDelegate {
    func handleAccept(_ acceptButton: UIButton)
    func handleIgnore()
    func handleBlock(_ blockButton: UIButton)
}

class WantToChatView: SpringView {
        
    //MARK: - Properties
    
    //UI
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    
    var delegate: WantToChatDelegate!
    
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
        guard let contentView = loadViewFromNib(nibName: "WantToChatView") else { return }
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        
        acceptButton.configuration?.imagePadding = 10
    }
        
    //MARK: - User Interaction
    
    @IBAction func acceptButtonDidTapped(_ sender: UIButton) {
        delegate.handleAccept(acceptButton)
    }
    
    @IBAction func ignoreButtonDidTapped(_ sender: UIButton) {
        delegate.handleIgnore()
    }
    
    @IBAction func blockButtonDidTapped(_ sender: UIButton) {
        delegate.handleBlock(acceptButton)
    }
    
}

//MARK: - Public Interface

extension WantToChatView {
    
    // Note: the constraints for the PostView should already be set-up when this is called.
    // Otherwise you'll get loads of constraint errors in the console
    func configure(firstName: String, delegate: WantToChatDelegate) {
        self.delegate = delegate
        nameLabel.text! += " " + firstName + "?"
    }
    
}
