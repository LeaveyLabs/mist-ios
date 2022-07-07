//
//  AuthStartViewController.swift
//  mist-ios
//
//  Created by Adam Monterey on 7/7/22.
//

import UIKit

class AuthStartViewController: UIViewController {
    
    var mistWideLogoView: MistWideLogoView!
    
    override func loadView() {
        super.loadView()
        loadMistLogo()
    }
    
    func loadMistLogo() {
        mistWideLogoView = MistWideLogoView()
        mistWideLogoView.setup(color: .pink)
        view.addSubview(mistWideLogoView)
        mistWideLogoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mistWideLogoView.widthAnchor.constraint(equalToConstant: 300),
            mistWideLogoView.heightAnchor.constraint(equalToConstant: 130),
            mistWideLogoView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            mistWideLogoView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mistWideLogoView.heartImageView.animation = ""
        mistWideLogoView.alpha = 0
        UIView.animate(withDuration: 3, delay: 0.3, options: .curveLinear) {
            self.mistWideLogoView.alpha = 1
        }
    }

}
