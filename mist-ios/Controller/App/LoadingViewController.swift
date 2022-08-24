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
    
//    var mistWideLogoView: MistWideLogoView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var didLoadEverything = false
    
    override func loadView() {
        super.loadView()
//        loadMistLogo()
    }
    
    func loadMistLogo() {
//        mistWideLogoView = MistWideLogoView()
//        mistWideLogoView.setup(color: .white)
//        view.addSubview(mistWideLogoView)
//        mistWideLogoView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            mistWideLogoView.widthAnchor.constraint(equalToConstant: 300),
//            mistWideLogoView.heightAnchor.constraint(equalToConstant: 130),
//            mistWideLogoView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
//            mistWideLogoView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
//        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserService.singleton.isLoggedIn() {
            goToAuth()
        } else {
            goToHome()
        }
    }
    
    func goToAuth() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Env.TRANSITION_TO_AUTH_DURATION) {
            transitionToStoryboard(storyboardID: Constants.SBID.SB.Auth,
                                    viewControllerID: Constants.SBID.VC.AuthNavigation,
                                    duration: Env.TRANSITION_TO_HOME_DURATION) { _ in}
        }
    }
    
    func goToHome() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self, !self.didLoadEverything else { return }
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
        }
        Task {
            try await loadAndGoHome(failCount: 0)
        }
    }
    
    func loadAndGoHome(failCount: Int) async throws {
        do {
            try await loadEverything()
            didLoadEverything = true
            Task {
                await UsersService.singleton.loadUsersAssociatedWithContacts() //for tagging
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Env.TRANSITION_TO_AUTH_DURATION) {
                transitionToStoryboard(storyboardID: Constants.SBID.SB.Main,
                                        viewControllerID: Constants.SBID.VC.TabBarController,
                                        duration: Env.TRANSITION_TO_HOME_DURATION) { _ in
                }
            }
        } catch {
            if let apiError = error as? APIError, apiError == .Unauthorized {
                logoutAndGoToAuth()
            }
            if failCount >= 2 {
                CustomSwiftMessages.displayError(error)
            }
            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 3)
            try await self.loadAndGoHome(failCount: failCount + 1)
        }
    }
}
