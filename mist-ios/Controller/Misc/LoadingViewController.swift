//
//  LaunchViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/06.
//

import UIKit

class LoadingViewController: UIViewController {
    
    let SHOULD_ANIMATE = false
    var FADING_ANIMATION_DELAY = 0.0
    var FADING_ANIMATION_DURATION = 0.0

    @IBOutlet weak var heartImageView: SpringImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if SHOULD_ANIMATE {
            FADING_ANIMATION_DELAY = 0.7
            FADING_ANIMATION_DELAY = 1.2
        }
        
        Task {
            var werePostsLoaded = false
            while !werePostsLoaded {
                do {
                    try await PostsService.loadInitialPosts()
                    werePostsLoaded = true
                    flyHeartUp()
                    DispatchQueue.main.asyncAfter(deadline: .now() + FADING_ANIMATION_DELAY) {
                        self.transitionToStoryboard(storyboardID: Constants.SBID.SB.Main,
                                                    viewControllerID: Constants.SBID.VC.TabBarController,
                                                    duration: self.FADING_ANIMATION_DURATION) { _ in}
                    }
                } catch {
                    CustomSwiftMessages.showError(errorDescription: error.localizedDescription)
                }
            }
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
