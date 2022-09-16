//
//  SceneDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/02/25.
//

import UIKit
import FirebaseAnalytics

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    static var visibleViewController: UIViewController? {
        get {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let delegate = windowScene.delegate as? SceneDelegate, let window = delegate.window else { return nil }
            guard let rootVC = window.rootViewController else { return nil }
            return getVisibleViewController(rootVC)
        }
    }
    
    static private func getVisibleViewController(_ rootViewController: UIViewController) -> UIViewController? {
        if let presentedViewController = rootViewController.presentedViewController {
            return getVisibleViewController(presentedViewController)
        }

        if let navigationController = rootViewController as? UINavigationController {
            return navigationController.visibleViewController
        }

        if let tabBarController = rootViewController as? UITabBarController {
            if let selectedTabVC = tabBarController.selectedViewController {
                return getVisibleViewController(selectedTabVC)
            }
            return tabBarController
        }

        return rootViewController
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            self.window = window
            
            let loadingVC = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "LoadingViewController") as! LoadingViewController
            if let notificationResponseHandler = generateNotificationResponseHandler(connectionOptions) {
                loadingVC.notificationResponseHandler = notificationResponseHandler
            }
                
            window.rootViewController = loadingVC
            window.makeKeyAndVisible()
        }
    }
    
    func generateNotificationResponseHandler(_ connectingOptions: UIScene.ConnectionOptions) -> NotificationResponseHandler? {
        guard
            let notificationResponse = connectingOptions.notificationResponse,
            let userInfo = notificationResponse.notification.request.content.userInfo as? [String : AnyObject],
            let notificationTypeString = userInfo[Notification.extra.type.rawValue] as? String,
            let notificationType = NotificationTypes.init(rawValue: notificationTypeString),
            let json = userInfo[Notification.extra.data.rawValue]
        else { return nil }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json as Any, options: .prettyPrinted)
            var handler = NotificationResponseHandler(notificationType: notificationType)
            switch notificationType {
            case .tag:
                handler.newTag = try JSONDecoder().decode(Tag.self, from: data)
            case .message:
                handler.newMessage = try JSONDecoder().decode(Message.self, from: data)
            case .match:
                handler.newMatchRequest = try JSONDecoder().decode(MatchRequest.self, from: data)
            case .daily_mistbox, .make_someones_day:
                break
            }
            return handler
        } catch {
            let analyticsId = "notiifcation"
            let analyticsTitle = "displayingVCafterRemoteNotificationFailed"
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
              AnalyticsParameterItemID: "id-\(analyticsId)",
              AnalyticsParameterItemName: analyticsTitle,
            ])
            return nil
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
//        guard let windowScene = (scene as? UIWindowScene) else { return }
//        let scene = UIWindow(windowScene: windowScene)
//        print("SCENE ROOT:", scene.rootViewController)

    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

