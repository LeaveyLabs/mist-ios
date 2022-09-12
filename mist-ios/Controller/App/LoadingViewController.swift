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
        group.addTask { try await ConversationService.singleton.loadMessageThreads() }
        group.addTask { try await FriendRequestService.singleton.loadFriendRequests() }
        group.addTask { try await MistboxManager.shared.fetchSyncedMistbox() }
        group.addTask { try await CommentService.singleton.fetchTaggedTags() }
        group.addTask { try await UsersService.singleton.loadTotalUserCount() }
        try await group.waitForAll()
    }
}

func loadPostStuff() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { try await PostService.singleton.loadExplorePosts() }
        group.addTask { try await PostService.singleton.loadSubmissions() }
        group.addTask { try await PostService.singleton.loadMentions() }
        group.addTask { try await FavoriteService.singleton.loadFavorites() }
        group.addTask { try await VoteService.singleton.loadVotes() }
        group.addTask { try await FlagService.singleton.loadFlags() }
        
        try await group.waitForAll()
    }
}

enum VersionError: Error {
    case invalidBundleInfo, invalidResponse
}

func isUpdateAvailable(completion: @escaping (Bool?, Error?) -> Void) throws -> URLSessionDataTask {
    guard let info = Bundle.main.infoDictionary,
        let currentVersion = info["CFBundleShortVersionString"] as? String,
        let identifier = info["CFBundleIdentifier"] as? String,
        let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(identifier)") else {
            throw VersionError.invalidBundleInfo
    }
    print("CURRENT", currentVersion)
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        do {
            if let error = error { throw error }
            guard let data = data else { throw VersionError.invalidResponse }
            let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
            guard let result = (json?["results"] as? [Any])?.first as? [String: Any], let newestVersion = result["version"] as? String else {
                throw VersionError.invalidResponse
            }
            let currentComponents: [Int] = currentVersion.components(separatedBy: ".").compactMap { Int($0) }
            let newestComponents: [Int] = newestVersion.components(separatedBy: ".").compactMap { Int($0) }
            guard currentComponents.count == 3, newestComponents.count == 3 else { return }
            if newestComponents[0] > currentComponents[0]  {
                completion(true, nil)
            } else if newestComponents[1] > currentComponents[1] {
                completion(true, nil)
            } else if newestComponents[2] > currentComponents[2] {
                completion(true, nil)
            }
            completion(false, nil)
        } catch {
            completion(nil, error)
        }
    }
    task.resume()
    return task
}

class LoadingViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var didLoadEverything = false
    var wasUpdateFoundAvailable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkForNewUpdate()
        if !UserService.singleton.isLoggedIntoAnAccount {
            goToAuth()
        } else {
            goToHome()
        }
    }
    
    func checkForNewUpdate() {
        _ = try? isUpdateAvailable { (isUpdateAvailable, error) in
            if let error = error {
                print(error)
            } else if let isUpdateAvailable = isUpdateAvailable {
                guard isUpdateAvailable else { return }
                self.wasUpdateFoundAvailable = true
                CustomSwiftMessages.showUpdateAvailableCard()
            }
        }
    }
    
    func goToAuth() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Env.TRANSITION_TO_AUTH_DURATION) {
            guard !self.wasUpdateFoundAvailable else { return }
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
            guard !wasUpdateFoundAvailable else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + Env.TRANSITION_TO_AUTH_DURATION) {
                transitionToStoryboard(storyboardID: Constants.SBID.SB.Main,
                                        viewControllerID: Constants.SBID.VC.TabBarController,
                                        duration: Env.TRANSITION_TO_HOME_DURATION) { _ in
                }
            }
        } catch {
            if let apiError = error as? APIError, apiError == .Unauthorized {
                logoutAndGoToAuth()
                return
            }
            if failCount >= 2 {
                CustomSwiftMessages.displayError(error)
            }
            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 3)
            try await self.loadAndGoHome(failCount: failCount + 1)
        }
    }
}
