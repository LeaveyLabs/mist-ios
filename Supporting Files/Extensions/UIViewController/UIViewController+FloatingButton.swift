//
//  UIViewController+FloatingButton.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import Foundation

extension UIViewController {
    
    func addFloatingButton() {
        let floatingButton = UIButton()
        view.addSubview(floatingButton)
        floatingButton.adjustsImageWhenHighlighted = false
        floatingButton.adjustsImageWhenDisabled = false
        floatingButton.setImage(UIImage(named: "submitbutton")!, for: .normal)
        floatingButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            floatingButton.heightAnchor.constraint(equalToConstant: 80),
            floatingButton.widthAnchor.constraint(equalToConstant: 80),
            floatingButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            floatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
        floatingButton.imageView?.contentMode = .scaleAspectFit
        floatingButton.contentHorizontalAlignment = .fill
        floatingButton.contentVerticalAlignment = .fill
        floatingButton.addTarget(self, action: #selector(floatingButtonPressed), for: .touchUpInside)
        floatingButton.applyMediumShadow()
        view.bringSubviewToFront(floatingButton)
    }

    @objc func floatingButtonPressed() {
        let newPostNav = storyboard!.instantiateViewController(withIdentifier: Constants.SBID.VC.NewPostNavigation)
        newPostNav.modalPresentationStyle = .fullScreen
        present(newPostNav, animated: true, completion: nil)
    }
    
}
