//
//  LaunchViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/06.
//

import UIKit

func loadEverything() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { try await loadPostStuff() }
        group.addTask { try await PostService.singleton.loadSubmissions() }
        group.addTask { try await ConversationService.singleton.loadMessageThreads() }
        group.addTask { try await FriendRequestService.singleton.loadFriendRequests() }
        
        try await group.waitForAll()
    }
}

func loadPostStuff() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { try await PostService.singleton.loadExplorePosts() }

        group.addTask { try await FavoriteService.singleton.loadFavorites() }
        group.addTask { try await VoteService.singleton.loadVotes() }
        group.addTask { try await FlagService.singleton.loadFlags() }
        
        try await group.waitForAll()
    }
}

class LoadingViewController: UIViewController {
    
    let SHOULD_ANIMATE = true
    var FADING_ANIMATION_DELAY: Double!
    var FADING_ANIMATION_DURATION: Double!
    
    var mistWideLogoView: MistWideLogoView!
    
    override func loadView() {
        super.loadView()
        loadMistLogo()
    }
    
    func loadMistLogo() {
        mistWideLogoView = MistWideLogoView()
        mistWideLogoView.setup(color: .white)
        view.addSubview(mistWideLogoView)
        mistWideLogoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mistWideLogoView.widthAnchor.constraint(equalToConstant: 300),
            mistWideLogoView.heightAnchor.constraint(equalToConstant: 130),
            mistWideLogoView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            mistWideLogoView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        FADING_ANIMATION_DELAY = SHOULD_ANIMATE ? 1.2 : 0
        FADING_ANIMATION_DURATION = SHOULD_ANIMATE ? 0.7 : 0
                        
        if !UserService.singleton.isLoggedIn() {
            goToAuth()
        } else {
            goToHome()
        }
    }
    
    func goToAuth() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
            mistWideLogoView.flyHeartUp()
            DispatchQueue.main.asyncAfter(deadline: .now() + FADING_ANIMATION_DELAY) {
                self.transitionToStoryboard(storyboardID: Constants.SBID.SB.Auth,
                                            viewControllerID: Constants.SBID.VC.AuthNavigation,
                                            duration: self.FADING_ANIMATION_DURATION) { _ in}
            }
        }
    }
    
    func goToHome() {
        Task {
            var numberOfFailures = 0
            var werePostsLoaded = false
            while !werePostsLoaded {
                do {
                    try await loadEverything()
                    werePostsLoaded = true
                    mistWideLogoView.flyHeartUp()
                    DispatchQueue.main.asyncAfter(deadline: .now() + FADING_ANIMATION_DELAY) {
                        self.transitionToStoryboard(storyboardID: Constants.SBID.SB.Main,
                                                    viewControllerID: Constants.SBID.VC.TabBarController,
                                                    duration: self.FADING_ANIMATION_DURATION) { _ in}
                    }
                } catch {
                    if numberOfFailures > 1 {
                        CustomSwiftMessages.displayError(error)
                    } else {
                        numberOfFailures += 1
                    }
                    sleep(2)
                }
            }
        }
    }
}
