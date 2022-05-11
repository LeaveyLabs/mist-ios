//
//  PostView.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/04/07.
//

import UIKit

class PostView: UIView {
    
    @IBAction func backgroundButtonDidPressed(_ sender: UIButton) {
        print("pressed")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configureView()
    }
    
    private func configureView() {
//        guard let view = self.loadViewFromNib(nibName: "PostView") else {return}
//        view.frame = self.bounds
//        self.addSubview(view)
    }
    
    func configurePost() {
        
    }
}
