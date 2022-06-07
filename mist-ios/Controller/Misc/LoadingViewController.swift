//
//  LaunchViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/06.
//

import UIKit

class LoadingViewController: UIViewController {
    
    @IBOutlet weak var heartImageView: SpringImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            do {
                try await PostsService.loadInitialPosts()
                self.flyHeartUp()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.transitionToStoryboard(storyboardID: Constants.SBID.SB.Main,
                                                viewControllerID: Constants.SBID.VC.TabBarController,
                                                duration: 1) { _ in}
                }
            } catch {
                CustomSwiftMessages.showError(errorDescription: error.localizedDescription)
            }
        }
    }
    
    func flyHeartUp() {
        let yDif: CGFloat = 3000
        let yPosition = heartImageView.frame.origin.y - yDif // Slide off the screen

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
