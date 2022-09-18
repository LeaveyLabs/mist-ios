//
//  LaunchViewController.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/06.
//

import UIKit
import FirebaseAnalytics

func loadEverything() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { try await loadPostStuff() }
        group.addTask { try await ConversationService.singleton.loadInitialMessageThreads() }
        group.addTask { try await FriendRequestService.singleton.loadFriendRequests() }
        group.addTask { try await MistboxManager.shared.fetchSyncedMistbox() }
        group.addTask { try await CommentService.singleton.fetchTaggedTags() }
        group.addTask { try await UsersService.singleton.loadTotalUserCount() }
        group.addTask { await UsersService.singleton.loadUsersAssociatedWithContacts() }
        try await group.waitForAll()
    }
}

func loadPostStuff() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { try await PostService.singleton.loadExploreFeedPostsIfPossible() }
        group.addTask { try await PostService.singleton.loadAndOverwriteExploreMapPosts() }
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
    let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData) //ignore local cache of old version
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
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
            //we need the == check in the following else ifs in case the apple testers are testing on 3.0.0 but 2.9.9 is available in the app store
            if newestComponents[0] > currentComponents[0]{
                completion(true, nil)
            } else if newestComponents[0] == currentComponents[0] &&
                    newestComponents[1] > currentComponents[1] {
                completion(true, nil)
            } else if newestComponents[0] == currentComponents[0] &&
                        newestComponents[1] == currentComponents[1] &&
                        newestComponents[2] > newestComponents[2] {
                completion(true, nil)
            } else {
                completion(false, nil)
            }
        } catch {
            completion(nil, error)
        }
    }
    task.resume()
    return task
}

class LoadingViewController: UIViewController {
    
    //UI
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //Flags
    var didLoadEverything = false
    var wasUpdateFoundAvailable = false
    var notificationResponseHandler: NotificationResponseHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkForNewUpdate()
        if !UserService.singleton.isLoggedIntoAnAccount {
            goToAuth()
        } else if notificationResponseHandler != nil {
            goToNotification()
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
        setupDelayedActivityIndicator()
        Task {
            try await loadAndGoHome(failCount: 0)
        }
    }
    
    func goToNotification() {
        setupDelayedActivityIndicator()
        Task {
            try await loadAndGoToNotification(failCount: 0)
        }
    }
    
    func loadAndGoHome(failCount: Int) async throws {
        do {
            try await loadEverything()
            didLoadEverything = true
            guard !wasUpdateFoundAvailable else { return }
            DispatchQueue.main.async {
                transitionToStoryboard(storyboardID: Constants.SBID.SB.Main,
                                        viewControllerID: Constants.SBID.VC.TabBarController,
                                        duration: Env.TRANSITION_TO_HOME_DURATION) { _ in }
            }
        } catch {
            try await handleInitialLoadError(error, reloadType: .home, failCount: failCount)
        }
    }
    
    func loadAndGoToNotification(failCount: Int) async throws {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await loadEverything() }
                group.addTask { try await self.loadNotificationData() }
                try await group.waitForAll()
            }
            didLoadEverything = true
            guard !wasUpdateFoundAvailable else { return }
            DispatchQueue.main.async {
                self.transitionToNotificationScreen()
            }
        } catch {
            try await handleInitialLoadError(error, reloadType: .notification, failCount: failCount)
        }
    }
    
    @MainActor
    func transitionToNotificationScreen() {
        guard let handler = notificationResponseHandler else { return }
        
        let mainSB = UIStoryboard(name: Constants.SBID.SB.Main, bundle: nil)
        guard let tabbarVC = mainSB.instantiateViewController(withIdentifier: Constants.SBID.VC.TabBarController) as? SpecialTabBarController else { return }
        transitionToViewController(tabbarVC, duration: Env.TRANSITION_TO_HOME_DURATION) { _ in }

        switch handler.notificationType {
        case .tag:
            guard let taggedPost = handler.newTaggedPost else {
                CustomSwiftMessages.displayError("not found", "this post has been deleted")
                return
            }
            guard
                let myAccountNavigation = mainSB.instantiateViewController(withIdentifier: Constants.SBID.VC.MyAccountNavigation) as? UINavigationController,
                let customExplore = CustomExploreParentViewController.create(setting: .mentions)
            else { return }
            tabbarVC.selectedIndex = 0
            myAccountNavigation.modalPresentationStyle = .fullScreen
            tabbarVC.present(myAccountNavigation, animated: false)
            myAccountNavigation.pushViewController(customExplore, animated: false)
            let newMentionsPostVC = PostViewController.createPostVC(with: taggedPost, shouldStartWithRaisedKeyboard: false, completionHandler: nil)
            myAccountNavigation.pushViewController(newMentionsPostVC, animated: false)
        case .message:
            guard let message = handler.newMessage,
                  let convo = ConversationService.singleton.getConversationWith(userId: message.sender) else {
                CustomSwiftMessages.displayError("not found", "these message have been deleted")
                return
            }
            tabbarVC.selectedIndex = 2
            guard
                let conversationsNavVC = tabbarVC.selectedViewController as? UINavigationController
            else { return }
            let chatVC = ChatViewController.create(conversation: convo)
            conversationsNavVC.pushViewController(chatVC, animated: false)
        case .match:
            guard let matchRequest = handler.newMatchRequest,
                  let convo = ConversationService.singleton.getConversationWith(userId: matchRequest.match_requesting_user) else {
                CustomSwiftMessages.displayError("not found", "these message have been deleted")
                return
            }
            tabbarVC.selectedIndex = 2
            guard
                let conversationsNavVC = tabbarVC.selectedViewController as? UINavigationController
            else { return }
            let chatVC = ChatViewController.create(conversation: convo)
            conversationsNavVC.pushViewController(chatVC, animated: false)
        case .daily_mistbox:
            tabbarVC.selectedIndex = 1
        case .make_someones_day:
            tabbarVC.selectedIndex = 0
            tabbarVC.presentNewPostNavVC(animated: false)
        }
    }
    
    func loadNotificationData() async throws {
        guard let handler = notificationResponseHandler else { return }
        switch handler.notificationType {
        case .tag:
            guard let tag = handler.newTag else { return }
            do {
                let loadedPost = try await PostAPI.fetchPostByPostID(postId: tag.post.id)
                self.notificationResponseHandler?.newTaggedPost = loadedPost
            } catch {
                //error will be handled in transitionToNotificaitonScreen
            }
        case .message, .match:
            break //we will already have loaded in the data in fetchConversations
        case .daily_mistbox:
            break
        case .make_someones_day:
            break
        }
    }
    
    //MARK: - Helpers
    
    func setupDelayedActivityIndicator() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self, !self.didLoadEverything else { return }
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
        }
    }
    
    enum InitialReloadType {
        case notification, home
    }
    
    func handleInitialLoadError(_ error: Error, reloadType: InitialReloadType, failCount: Int) async throws {
        if let apiError = error as? APIError, apiError == .Unauthorized {
            logoutAndGoToAuth()
            return
        }
        if failCount >= 2 {
            CustomSwiftMessages.displayError(error)
        }
        try await Task.sleep(nanoseconds: NSEC_PER_SEC * 3)
        switch reloadType {
        case .notification:
            try await self.loadAndGoToNotification(failCount: failCount + 1)
        case .home:
            try await self.loadAndGoHome(failCount: failCount + 1)
        }
    }
    
}
