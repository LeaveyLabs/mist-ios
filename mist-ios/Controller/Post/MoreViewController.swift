//
//  OkViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/13.
//

import UIKit

class MoreViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    //TODO: make drop down arrow image go completely behind sortbybutton in postviewcontroller
    
    @IBOutlet weak var containingView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    
    var delegate: PostCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.layer.cornerRadius = 5
//        containingView.layer.cornerRadius = 10
        view.layer.cornerRadius = 15
        
        modalPresentationStyle = .custom
        transitioningDelegate = self
        
        //containingView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Only curve top corners
    }
    
    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    
        //https://developer.apple.com/library/archive/technotes/tn2444/_index.html
        //TODO: use Open Graph protocols on our website for a Rich imessage display
    @IBAction func shareButton(_ sender: UIButton) {
        dismiss(animated: true) { [self] in
            delegate?.presentShareActivityVC()
        }
    }
    
    func activityViewDidDismiss() {
        self.dismiss(animated: true)
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func reportButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        let controller: UISheetPresentationController = .init(presentedViewController: presented, presenting: presenting)
        let small: UISheetPresentationController.Detent = ._detent(withIdentifier: "small", constant: 300.0)
        
//        controller.prefersScrollingExpandsWhenScrolledToEdge
        controller.prefersGrabberVisible = false
        controller.detents = [small]
        
        return controller
    }
}
